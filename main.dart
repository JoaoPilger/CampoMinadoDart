import 'dart:math';
import 'dart:io';

void main(){
  Tabuleiro tabuleiro = Tabuleiro(12);

  while (true) {
    stdout.writeln('\n=== CAMPO MINADO ===');
    stdout.writeln('Comandos:');
    stdout.writeln('- abrir:  a LINHA COLUNA   (ex: a 3 5)');
    stdout.writeln('- flag:   f LINHA COLUNA   (ex: f 3 5)');
    stdout.writeln('- sair:   s');
    stdout.writeln('');

    tabuleiro.printTabuleiro();

    if (tabuleiro.jogoAcabou) {
      stdout.writeln('\nVocê perdeu. (bomba)');
      break;
    }

    if (tabuleiro.venceu) {
      stdout.writeln('\nVocê venceu! (todas as casas seguras abertas)');
      break;
    }

    stdout.write('\n> ');
    final entrada = stdin.readLineSync();
    if (entrada == null) continue;

    final partes = entrada.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) continue;

    final comando = partes[0].toLowerCase();
    if (comando == 's') break;

    if (partes.length < 3) {
      stdout.writeln('Entrada inválida. Ex: a 3 5  ou  f 3 5');
      continue;
    }

    final linha = int.tryParse(partes[1]);
    final coluna = int.tryParse(partes[2]);
    if (linha == null || coluna == null) {
      stdout.writeln('Linha/coluna inválidas.');
      continue;
    }

    final i = linha - 1;
    final j = coluna - 1;

    if (!tabuleiro.dentro(i, j)) {
      stdout.writeln('Fora do tabuleiro.');
      continue;
    }

    if (comando == 'a') {
      tabuleiro.abrir(i, j);
    } else if (comando == 'f') {
      tabuleiro.alternarFlag(i, j);
    } else {
      stdout.writeln('Comando desconhecido.');
    }
  }
}

class Casa{
  final int? bomba;
  int flag = 0;
  bool aberta = false;
  String casa = "⬜";
  String casaBomba = "💣";
  String casaFlag = "🚩";

  Casa(this.bomba, this.flag);

  @override
  String toString(){
    if (!aberta && flag == 1) {
      return casaFlag;
    }

    if (!aberta) return casa;

    return casa;
  }

}

class Tabuleiro{
  final int tamanho;

  List<List<Casa>> tabuleiro = [];
  bool jogoAcabou = false;
  final int quantBomba;
  bool _bombasGeradas = false;
  bool get jogoFinalizado => jogoAcabou || venceu;

  Tabuleiro(this.tamanho) : quantBomba = ((tamanho * tamanho) * 0.30) ~/ 1 {
    for (var i = 0; i < tamanho; i++) {
      final linha = <Casa>[];
      for (var j = 0; j < tamanho; j++) {
        linha.add(Casa(0, 0));
      }
      tabuleiro.add(linha);
    }

  }

  bool get venceu {
    if (jogoAcabou) return false;

    for (var i = 0; i < tamanho; i++) {
      for (var j = 0; j < tamanho; j++) {
        final c = tabuleiro[i][j];
        if ((c.bomba ?? 0) == 0 && !c.aberta) return false;
      }
    }
    return true;
  }

  bool dentro(int i, int j) => i >= 0 && i < tamanho && j >= 0 && j < tamanho;

  bool _naAreaSeguraPrimeiroClique(int i, int j, int si, int sj) {
    return (i - si).abs() <= 1 && (j - sj).abs() <= 1;
  }

  void _gerarBombas(int si, int sj) {
    if (_bombasGeradas) return;

    final random = Random();
    int colocadas = 0;

    while (colocadas < quantBomba) {
      final i = random.nextInt(tamanho);
      final j = random.nextInt(tamanho);

      if (_naAreaSeguraPrimeiroClique(i, j, si, sj)) continue;
      final c = tabuleiro[i][j];
      if ((c.bomba ?? 0) == 1) continue;

      tabuleiro[i][j] = Casa(1, 0);
      colocadas++;
    }

    _bombasGeradas = true;
  }

  int bombasAoRedor(int i, int j) {
    int total = 0;
    for (var di = -1; di <= 1; di++) {
      for (var dj = -1; dj <= 1; dj++) {
        if (di == 0 && dj == 0) continue;
        final ni = i + di;
        final nj = j + dj;
        if (!dentro(ni, nj)) continue;
        if ((tabuleiro[ni][nj].bomba ?? 0) == 1) total++;
      }
    }
    return total;
  }

  void revelarBombas() {
    for (var i = 0; i < tamanho; i++) {
      for (var j = 0; j < tamanho; j++) {
        final c = tabuleiro[i][j];
        if ((c.bomba ?? 0) == 1) {
          c.aberta = true;
          c.casa = c.casaBomba;
        }
      }
    }
  }

  void alternarFlag(int i, int j) {
    if (jogoFinalizado) return;
    final c = tabuleiro[i][j];
    if (c.aberta) return;
    c.flag = (c.flag == 1) ? 0 : 1;
  }

  void abrir(int i, int j) {
    if (jogoFinalizado) return;

    if (!_bombasGeradas) {
      _gerarBombas(i, j);
    }

    final inicio = tabuleiro[i][j];
    if (inicio.aberta) return;
    if (inicio.flag == 1) return;

    if ((inicio.bomba ?? 0) == 1) {
      jogoAcabou = true;
      revelarBombas();
      return;
    }

    final fila = <List<int>>[];
    fila.add([i, j]);

    while (fila.isNotEmpty) {
      final atual = fila.removeLast();
      final ci = atual[0];
      final cj = atual[1];
      if (!dentro(ci, cj)) continue;

      final c = tabuleiro[ci][cj];
      if (c.aberta) continue;
      if (c.flag == 1) continue;
      if ((c.bomba ?? 0) == 1) continue;

      final n = bombasAoRedor(ci, cj);
      c.aberta = true;
      if (n == 0) {
        c.casa = "  ";
      } else {
        c.casa = n.toString().padLeft(2, ' ');
      }

      if (n == 0) {
        for (var di = -1; di <= 1; di++) {
          for (var dj = -1; dj <= 1; dj++) {
            if (di == 0 && dj == 0) continue;
            final ni = ci + di;
            final nj = cj + dj;
            if (dentro(ni, nj)) fila.add([ni, nj]);
          }
        }
      }
    }
  }

  void printTabuleiro(){
    stdout.write('   ');
    for (var a = 0; a < tamanho; a++) {
      final coluna = (a + 1).toString().padLeft(2, ' ');
      stdout.write('$coluna ');
    }
    stdout.write('\n');

    for (var i = 0; i < this.tamanho; i++) {
      int linha = i+1;

      for (var j = 0; j < this.tamanho; j++) {
        final cell = this.tabuleiro[i][j].toString();
        stdout.write(cell.padLeft(2, ' '));
        stdout.write(' ');

      }

      stdout.write("-$linha");
      stdout.write('\n');
    }
  }

  @override
    String toString(){
      return tabuleiro.map((linha) => linha.join(' ')).join('\n');
    }

}