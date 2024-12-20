String modifyString(String input) {
  if (input.contains('=')) {
    // Menghapus '=' dan kata setelahnya, kemudian menambahkan 'Set' di awal string
    input = input.split('=')[0]; // Mengambil bagian sebelum '='
    return 'Set ${input.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}';
  } else if (input.contains('?')) {
    // Menghapus '?' dan kata setelahnya, kemudian menambahkan 'Get' di awal string
    input = input.split('?')[0]; // Mengambil bagian sebelum '?'
    return 'Get ${input.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}';
  } else if (input.contains('!')) {
    // Menghapus '!' dan kata setelahnya
    input = input.split('!')[0]; // Mengambil bagian sebelum '!'
    return input
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' '); // Mengubah format nama
  }
  return input
      .split('_')
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(' '); // Mengubah format nama
}
