#!/usr/bin/env python3
"""DAP proxy that adds Flutter hot reload on Dart file changes."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any, IO


class DapProxy:
    def __init__(self) -> None:
        self.log_path = Path("/tmp/zed-flutter-dap-proxy.log")
        self.log_lock = threading.Lock()
        self.log(f"proxy started (pid {os.getpid()})")

        flutter = os.environ.get("ZED_REAL_FLUTTER") or shutil.which("flutter")
        if flutter is None:
            raise RuntimeError("flutter was not found in PATH")

        self.adapter = subprocess.Popen(
            [flutter, "debug_adapter"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=None,
        )
        if self.adapter.stdin is None or self.adapter.stdout is None:
            raise RuntimeError("failed to open Dart debug adapter pipes")

        self.adapter_stdin = self.adapter.stdin
        self.adapter_stdout = self.adapter.stdout
        self.adapter_write_lock = threading.Lock()
        self.client_write_lock = threading.Lock()
        self.internal_lock = threading.Lock()
        self.internal_requests: set[int] = set()
        self.next_internal_sequence = 2_147_000_000
        self.flutter_ready = threading.Event()
        self.stopping = threading.Event()
        self.watcher: subprocess.Popen[bytes] | None = None

    def log(self, message: str) -> None:
        line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}"
        with self.log_lock:
            with self.log_path.open("a", encoding="utf-8") as log_file:
                print(line, file=log_file)
        print(line, file=sys.stderr)

    @staticmethod
    def read_message(stream: IO[bytes]) -> dict[str, Any] | None:
        headers: dict[str, str] = {}
        while True:
            line = stream.readline()
            if not line:
                return None
            if line in (b"\r\n", b"\n"):
                break
            name, separator, value = line.decode("ascii").partition(":")
            if not separator:
                raise RuntimeError(f"invalid DAP header: {line!r}")
            headers[name.lower()] = value.strip()

        length = int(headers["content-length"])
        body = stream.read(length)
        if len(body) != length:
            return None
        return json.loads(body.decode("utf-8"))

    @staticmethod
    def encode_message(message: dict[str, Any]) -> bytes:
        body = json.dumps(message, separators=(",", ":")).encode("utf-8")
        return f"Content-Length: {len(body)}\r\n\r\n".encode("ascii") + body

    def write_adapter(self, message: dict[str, Any]) -> None:
        payload = self.encode_message(message)
        with self.adapter_write_lock:
            self.adapter_stdin.write(payload)
            self.adapter_stdin.flush()

    def write_client(self, message: dict[str, Any]) -> None:
        payload = self.encode_message(message)
        with self.client_write_lock:
            sys.stdout.buffer.write(payload)
            sys.stdout.buffer.flush()

    def start_watcher(self, cwd: str) -> None:
        if self.watcher is not None:
            return

        lib = Path(cwd) / "lib"
        if not lib.is_dir():
            print(f"Flutter hot reload watcher: {lib} does not exist", file=sys.stderr)
            return

        fswatch = shutil.which("fswatch")
        if fswatch is None:
            print("Flutter hot reload watcher: fswatch was not found in PATH", file=sys.stderr)
            return

        self.watcher = subprocess.Popen(
            [
                fswatch,
                "-o",
                "-r",
                "--latency=0.5",
                "--include=\\.dart$",
                "--exclude=.*",
                str(lib),
            ],
            stdout=subprocess.PIPE,
            stderr=sys.stderr,
        )
        threading.Thread(target=self.watch_changes, daemon=True).start()
        self.log(f"watching {lib}")

    def watch_changes(self) -> None:
        if self.watcher is None or self.watcher.stdout is None:
            return

        for _ in self.watcher.stdout:
            if self.stopping.is_set():
                return
            if self.flutter_ready.is_set():
                self.request_hot_reload()

    def request_hot_reload(self) -> None:
        with self.internal_lock:
            sequence = self.next_internal_sequence
            self.next_internal_sequence -= 1
            self.internal_requests.add(sequence)

        try:
            self.log("requesting hot reload")
            self.write_adapter(
                {
                    "seq": sequence,
                    "type": "request",
                    "command": "hotReload",
                    "arguments": {"reason": "save"},
                }
            )
        except (BrokenPipeError, OSError):
            with self.internal_lock:
                self.internal_requests.discard(sequence)

    def forward_adapter_messages(self) -> None:
        try:
            while (message := self.read_message(self.adapter_stdout)) is not None:
                if message.get("type") == "event":
                    event = message.get("event")
                    if event == "flutter.appStarted":
                        self.flutter_ready.set()
                        self.log("Flutter app started; hot reload enabled")
                    elif event in ("terminated", "exited"):
                        self.flutter_ready.clear()

                if message.get("type") == "response":
                    request_sequence = message.get("request_seq")
                    with self.internal_lock:
                        internal = request_sequence in self.internal_requests
                        if internal:
                            self.internal_requests.discard(request_sequence)
                    if internal:
                        if not message.get("success", False):
                            error = message.get("message", "unknown error")
                            self.log(f"hot reload failed: {error}")
                        else:
                            self.log("hot reload completed")
                        continue

                self.write_client(message)
        except (BrokenPipeError, OSError, RuntimeError, ValueError) as error:
            if not self.stopping.is_set():
                print(f"Flutter DAP proxy read error: {error}", file=sys.stderr)
        finally:
            self.stopping.set()

    def run(self) -> int:
        adapter_reader = threading.Thread(target=self.forward_adapter_messages, daemon=True)
        adapter_reader.start()

        try:
            while (message := self.read_message(sys.stdin.buffer)) is not None:
                if (
                    message.get("type") == "request"
                    and message.get("command") == "launch"
                ):
                    arguments = message.get("arguments") or {}
                    if arguments.get("type") == "flutter":
                        cwd = arguments.get("cwd") or os.getcwd()
                        self.start_watcher(cwd)

                self.write_adapter(message)
        except (BrokenPipeError, OSError, RuntimeError, ValueError) as error:
            if not self.stopping.is_set():
                print(f"Flutter DAP proxy write error: {error}", file=sys.stderr)
        finally:
            self.stop()

        return self.adapter.wait()

    def stop(self) -> None:
        if self.stopping.is_set() and self.adapter.poll() is not None:
            return
        self.stopping.set()
        if self.watcher is not None and self.watcher.poll() is None:
            self.watcher.terminate()
        if self.adapter.poll() is None:
            self.adapter.terminate()


def main() -> int:
    try:
        return DapProxy().run()
    except Exception as error:
        print(f"Flutter DAP proxy failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
