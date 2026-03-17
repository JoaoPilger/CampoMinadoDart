import 'dart:math';
import 'dart:io';

void main(){
  print("Dificuldade:\n1 - Fácil\n2 - Médio\n3 - Difícil\n4 - Custom\nEscolha uma opção válida: ");
  String? escolha = stdin.readLineSync();
  int? escolhaParse = int.tryParse(escolha ?? '0');

  int tamanhoTab = escolhaParse ?? 0;
  
  Tabuleiro tabuleiro = Tabuleiro(tamanhoTab, 0);

  tabuleiro.printTabuleiro();
}

class Casa{
  final int? bomba;
  int flag = 0;
  String casa = "⬜";
  String casaBomba = "💣";
  String casaFlag = "🚩";

  Casa(this.bomba, this.flag);

  @override
  String toString(){
    if (flag == 1) {
      return casaFlag;
    } else{
      return casa;
    }
  }

}

class Tabuleiro{
  int tamanho;

  List<List<Casa>> tabuleiro = [];

  Tabuleiro(escolhaParse, this.tamanho){
    if ( escolhaParse != null) {
      if (escolhaParse == 1) {
        tamanho = 8;

      }else if(escolhaParse == 2){
        tamanho = 12;

      }else if(escolhaParse == 3){
        tamanho = 16;

      }else if(escolhaParse == 4){
        print("Escolha um tamanho de tabuleiro. Ex: 16 (vai ser um tabuleiro 16x16):");
        String? escolha2 = stdin.readLineSync();

        int? escolhaParse2 = int.tryParse(escolha2 ?? '');
        if (escolhaParse2 != null) {

          tamanho = escolhaParse2;
        }
      }
    }else{
      print("Valor inválido, você perdeu!");
      exit(1);
    }

    final int quantBomba = ((tamanho*tamanho)*0.30)~/1;

    var random = Random();
    int bombaColocada = 0;

    for (var i = 0; i < tamanho; i++) {
      List<Casa> linha = [];

      for (var j = 0; j < tamanho; j++) {
        int num = random.nextInt(10);

        if (num >= 7 && bombaColocada < quantBomba) {
          Casa casa = Casa(1, 0);
          linha.add(casa);
          bombaColocada = bombaColocada + 1;

        } else{
          Casa casa = Casa(0, 0);
          linha.add(casa);
        }
      }

      tabuleiro.add(linha);
    }

  }

  void printTabuleiro(){
    for (var a = 0; a < this.tamanho; a++) {
      int coluna = a+1;
      if (coluna == 1) {
        stdout.write(" $coluna  ");
      }else if(coluna >= 10){
        stdout.write("$coluna ");
      }else{
        stdout.write("$coluna  ");
      }
    }

    stdout.write('\n');
    for (var i = 0; i < this.tamanho; i++) {
      int linha = i+1;

      for (var j = 0; j < this.tamanho; j++) {
        stdout.write(this.tabuleiro[i][j]);
        stdout.write(" ");

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