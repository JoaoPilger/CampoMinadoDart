import 'dart:math';
import 'dart:io';

void main() {
  print("Dificuldade:\n1 - Fácil\n2 - Médio\n3 - Difícil\n4 - Custom\nEscolha uma opção válida: ");
  String? escolha = stdin.readLineSync();
  int? escolhaParse = int.tryParse(escolha ?? '0');

  // Inicializa o tabuleiro com a escolha do usuário
  Tabuleiro tabuleiro = Tabuleiro(escolhaParse);

  while (true) {
    stdout.writeln('\n=== CAMPO MINADO ===');
    stdout.writeln('Comandos:');
    stdout.writeln('- abrir:  a LINHA COLUNA   (ex: a 3 5)');
    stdout.writeln('- flag:   f LINHA COLUNA   (ex: f 3 5)');
    stdout.writeln('- sair:   s');

    tabuleiro.printTabuleiro();

    if (tabuleiro.jogoAcabou) {
      stdout.writeln('\n Você perdeu! Acertou uma bomba.');
      break;
    }

    if (tabuleiro.venceu) {
      stdout.writeln('\n Parabéns! Você Ganhou!');
      break;
    }

    stdout.write('\n> ');
    final entrada = stdin.readLineSync();
    if (entrada == null || entrada.isEmpty) continue;

    final partes = entrada.trim().split(RegExp(r'\s+'));
    final comando = partes[0].toLowerCase();

    if (comando == 's') break;

    if (partes.length < 3) {
      stdout.writeln('Entrada inválida. Ex: a 3 5 ou f 3 5');
      continue;
    }

    final linha = int.tryParse(partes[1]);
    final coluna = int.tryParse(partes[2]);

    if (linha == null || coluna == null) {
      stdout.writeln('Linha/coluna devem ser números.');
      continue;
    }

    final i = linha - 1;
    final j = coluna - 1;

    if (!tabuleiro.dentro(i, j)) {
      stdout.writeln('Coordenadas fora do tabuleiro.');
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

class Casa {
  int bomba = 0; // 0 para seguro, 1 para bomba
  int flag = 0; // 0 para sem flag, 1 para com flag
  bool aberta = false;
  String visual = "⬜";

  static const String casaBomba = "💣";
  static const String casaFlag = "🚩";

  @override
  String toString() {
    if (!aberta) {
      return (flag == 1) ? casaFlag : visual;
    }
    return visual; // Se aberta, mostra o conteúdo atualizado (número ou vazio)
  }
}

class Tabuleiro {
  late int tamanho;
  late int quantBomba;
  List<List<Casa>> grade = [];
  bool jogoAcabou = false;
  bool _bombasGeradas = false;

  bool get jogoFinalizado => jogoAcabou || venceu;

  Tabuleiro(int? escolha) {
    // Definir tamanho com base na dificuldade
    switch (escolha) {
      case 1: tamanho = 8; break;
      case 2: tamanho = 12; break;
      case 3: tamanho = 16; break;
      case 4:
        stdout.write("Digite o tamanho personalizado (ex: 10): ");
        tamanho = int.tryParse(stdin.readLineSync() ?? '8') ?? 8;
        break;
      default:
        print("Opção inválida. Iniciando no Fácil.");
        tamanho = 8;
    }

    // Define quantidade de bombas (aprox 15% do mapa para não ser impossível)
    quantBomba = (tamanho * tamanho * 0.15).toInt();
    if (quantBomba < 1) quantBomba = 1;

    // Inicializa a grade com casas vazias
    for (var i = 0; i < tamanho; i++) {
      grade.add(List.generate(tamanho, (_) => Casa()));
    }
  }

  bool get venceu {
    if (jogoAcabou) return false;
    for (var i = 0; i < tamanho; i++) {
      for (var j = 0; j < tamanho; j++) {
        // Se existe uma casa sem bomba que não foi aberta, ainda não venceu
        if (grade[i][j].bomba == 0 && !grade[i][j].aberta) return false;
      }
    }
    return true;
  }

  bool dentro(int i, int j) => i >= 0 && i < tamanho && j >= 0 && j < tamanho;

  void _gerarBombas(int si, int sj) {
    final random = Random();
    int colocadas = 0;

    while (colocadas < quantBomba) {
      int i = random.nextInt(tamanho);
      int j = random.nextInt(tamanho);

      // Não coloca bomba onde o usuário clicou pela primeira vez (raio de 1)
      bool areaSegura = (i - si).abs() <= 1 && (j - sj).abs() <= 1;
      
      if (!areaSegura && grade[i][j].bomba == 0) {
        grade[i][j].bomba = 1;
        colocadas++;
      }
    }
    _bombasGeradas = true;
  }

  int bombasAoRedor(int i, int j) {
    int total = 0;
    for (var di = -1; di <= 1; di++) {
      for (var dj = -1; dj <= 1; dj++) {
        int ni = i + di;
        int nj = j + dj;
        if (dentro(ni, nj) && grade[ni][nj].bomba == 1) total++;
      }
    }
    return total;
  }

  void abrir(int i, int j) {
    if (jogoFinalizado || grade[i][j].aberta || grade[i][j].flag == 1) return;

    if (!_bombasGeradas) _gerarBombas(i, j);

    if (grade[i][j].bomba == 1) {
      jogoAcabou = true;
      _revelarTudo();
      return;
    }

    // Algoritmo de expansão (Flood Fill)
    List<List<int>> fila = [[i, j]];
    while (fila.isNotEmpty) {
      var pos = fila.removeLast();
      int ci = pos[0];
      int cj = pos[1];

      if (!dentro(ci, cj) || grade[ci][cj].aberta || grade[ci][cj].flag == 1) continue;

      int n = bombasAoRedor(ci, cj);
      grade[ci][cj].aberta = true;
      grade[ci][cj].visual = n == 0 ? "  " : " $n";

      if (n == 0) {
        for (var di = -1; di <= 1; di++) {
          for (var dj = -1; dj <= 1; dj++) {
            if (di != 0 || dj != 0) fila.add([ci + di, cj + dj]);
          }
        }
      }
    }
  }

  void alternarFlag(int i, int j) {
    if (!grade[i][j].aberta) {
      grade[i][j].flag = (grade[i][j].flag == 1) ? 0 : 1;
    }
  }

  void _revelarTudo() {
    for (var i = 0; i < tamanho; i++) {
      for (var j = 0; j < tamanho; j++) {
        if (grade[i][j].bomba == 1) {
          grade[i][j].aberta = true;
          grade[i][j].visual = Casa.casaBomba;
        }
      }
    }
  }

  void printTabuleiro() {
    stdout.write('   ');
    for (var i = 0; i < tamanho; i++) {
      stdout.write((i + 1).toString().padLeft(2, ' ') + ' ');
    }
    stdout.writeln();

    for (var i = 0; i < tamanho; i++) {
      stdout.write((i + 1).toString().padLeft(2, ' ') + ' ');
      for (var j = 0; j < tamanho; j++) {
        stdout.write('${grade[i][j]} ');
      }
      stdout.writeln();
    }
  }
}