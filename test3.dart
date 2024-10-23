// import 'dart:io';

// void main() {
//   int rows =
//       7; // Set to any odd number, like 7 or 9 (needs to be odd for symmetry)
//   if (rows % 2 == 0) {
//     print('Please provide an odd number of rows to ensure symmetry.');
//     return;
//   }

//   int middle = rows ~/ 2; // Middle index for symmetry

//   for (int i = 0; i < rows; i++) {
//     for (int j = 0; j < rows; j++) {
//       // Dynamic conditions for placing asterisks based on the row and column
//       if ((i == 0 && j == middle) ||
//           (i == 1 && (j == middle - 1 || j == middle + 1)) ||
//           (i == 2 && (j == middle - 2 || j == middle || j == middle + 2)) ||
//           (i == middle && (j % 2 == 0))) {
//         // Middle row (i == middle), even columns only
//         stdout.write('* ');
//       } else if ((i == rows - 3 &&
//               (j == middle - 2 || j == middle || j == middle + 2)) ||
//           (i == rows - 2 && (j == middle - 1 || j == middle + 1)) ||
//           (i == rows - 1 && j == middle)) {
//         stdout.write('* ');
//       } else {
//         stdout.write('  '); // Space for non-asterisk positions
//       }
//     }
//     print(''); // Move to the next line after each row
//   }
// }

import 'dart:io';

void main(List<String> args) {
  const int row = 5;
  for (int i = 0; i < row; i++) {
    stdout.writeln(" " * (row - i) + "* " * i);
  }
  // void printSpaces(int count) {
  //   for (var v = 0; v < count; v++) {
  //     stdout.write(' ');
  //   }
  // }

  // void printStar(int count) {
  //   for (var v = 0; v < count; v++) {
  //     stdout.write('* ');
  //   }
  // }

  // var x = 07;
  // var y = x ~/ 2;
  // if (x == y) {
  //   printStar(x);
  // }
  // if (x != y) {
  //   printSpaces((x ~/ 2));
  // }
}
