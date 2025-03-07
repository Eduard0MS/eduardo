# Jogo de Plataforma em Assembly

Este é um jogo de plataforma simples desenvolvido em Assembly x86 para DOS. O jogador controla um personagem que deve desviar de obstáculos no chão e no ar, com um sistema de pontuação e aumento progressivo de velocidade.

## Características do Jogo

- **Controles Simples:**

  - ESPAÇO: Pular (pressione duas vezes para pulo duplo)
  - ESC: Sair do jogo

- **Mecânicas:**

  - Sistema de pulo duplo
  - Obstáculos no chão e no ar
  - Aumento progressivo de velocidade a cada 10 segundos
  - Sistema de multiplicador de velocidade (1x até 9x)
  - Sistema de pontuação e high score
  - Colisões adaptativas baseadas na velocidade

- **Interface:**
  - Placar de pontuação atual
  - Recorde (high score)
  - Indicador de velocidade atual
  - Menu simples com opções de iniciar e sair

## Requisitos

- DOSBox ou ambiente DOS compatível
- NASM (Netwide Assembler)

## Como Compilar e Executar

1. **Instalar o NASM:**

   - Baixe o NASM do site oficial: https://www.nasm.us/
   - Adicione o NASM ao PATH do sistema

2. **Compilar o Jogo:**

   ```bash
   nasm -f bin simple_game.asm -o SIMPLE_2.COM
   ```

3. **Executar no DOSBox:**
   - Monte o diretório do jogo no DOSBox
   - Execute o arquivo SIMPLE_2.COM

## Como Jogar

1. No menu inicial:

   - Pressione '3' para iniciar o jogo
   - Pressione 'ESC' para sair

2. Durante o jogo:

   - Use ESPAÇO para pular
   - Pressione ESPAÇO novamente no ar para fazer um pulo duplo
   - Desvie dos obstáculos vermelhos
   - Tente conseguir a maior pontuação possível
   - A velocidade aumenta a cada 10 segundos

3. Após perder:
   - Pressione ESPAÇO para voltar ao menu
   - Seu high score será salvo

## Detalhes Técnicos

- Desenvolvido em Assembly x86 16-bit
- Modo de vídeo VGA 320x200 (Modo 13h)
- Utiliza interrupções do BIOS e DOS para entrada/saída
- Sistema de som através da porta do PC Speaker
- Otimizado para performance com técnicas de double buffering

## Estrutura do Código

- `simple_game.asm`: Código fonte principal
- Seções principais:
  - `.data`: Variáveis e constantes
  - `.text`: Código do jogo
  - Funções principais:
    - `update_game`: Lógica principal do jogo
    - `render`: Sistema de renderização
    - `process_input`: Processamento de entrada
    - `check_collision`: Sistema de colisões

## Contribuições

Sinta-se à vontade para contribuir com o projeto através de pull requests. Algumas sugestões de melhorias:

- Adicionar efeitos visuais
- Implementar novos tipos de obstáculos
- Adicionar power-ups
- Melhorar os gráficos
- Adicionar música de fundo

## Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.
