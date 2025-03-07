[BITS 16]
[ORG 0x100]

section .data
    SCREEN_WIDTH    equ 320
    SCREEN_HEIGHT   equ 200
    BUFFER_SIZE     equ SCREEN_WIDTH * SCREEN_HEIGHT
    BLOCK_SIZE      equ 16
    GROUND_HEIGHT   equ 150
    SPEED_UP_TIME   equ 182      ; Aproximadamente 10 segundos (18.2 ticks por segundo)
    MAX_SPEED       equ 20       ; Velocidade máxima para evitar overflow
    player_x        dw 40
    player_y        dw 134
    player_vy       dw 0
    is_jumping      db 0
    can_double_jump db 1      ; Novo: flag para pulo duplo
    gravity         dw 2      ; Aumentado para 2 novamente
    jump_strength   dw -12    ; Força do pulo ajustada para -12
    obstacle_x      dw 320
    obstacle_y      dw 134
    obstacle_height dw 16
    obstacle_width  dw 16
    sky_obstacle_x  dw 320     ; Novo: obstáculo do céu
    sky_obstacle_y  dw 90      ; Novo: altura fixa do obstáculo do céu
    sky_active      db 0       ; Novo: flag para obstáculo do céu ativo
    obstacle_speed  dw 4      ; Velocidade base aumentada
    base_speed      dw 4      ; Velocidade base aumentada
    speed_timer     dw 0
    speed_interval  dw 200    ; Intervalo menor = aumenta velocidade mais rápido
    score           dw 0
    high_score      dw 0
    game_over       db 0
    difficulty      db 1
    score_msg       db 'Score: $'
    high_score_msg  db 'High Score: $'
    speed_msg       db 'Speed: $'    ; Nova mensagem para velocidade
    speed_x_msg     db 'x$'          ; Para mostrar o "x" após o número
    score_str       times 6 db 0
    speed_str       times 3 db 0     ; Buffer para o multiplicador de velocidade
    game_over_msg   db 'GAME OVER! Pressione ESPACO para reiniciar$'
    difficulty_msg  db 'Menu:$'
    easy_msg       db '3 - Iniciar Jogo$'
    exit_msg       db 'ESC - Sair$'
    screen_buffer   times BUFFER_SIZE db 0  ; Buffer secundário
    time_alive      dw 0         ; Novo: contador de tempo vivo
    last_boost_time dw 0         ; Novo: tempo do último boost
    speed_boosted   db 0         ; Novo: flag para indicar se velocidade já foi aumentada
    speed_mult      db 1      ; Novo: multiplicador atual de velocidade

section .text
    global _start

_start:
    call show_difficulty_select
    jmp main_loop

show_difficulty_select:
    ; Limpar tela
    mov ax, 0003h
    int 10h

    ; Mostrar mensagem de seleção
    mov ah, 2
    mov bh, 0
    mov dh, 10
    mov dl, 10
    int 10h
    mov ah, 9
    mov dx, difficulty_msg
    int 21h

    ; Mostrar opção de iniciar
    mov ah, 2
    mov dh, 12
    mov dl, 10
    int 10h
    mov ah, 9
    mov dx, easy_msg
    int 21h

    ; Adicionar opção de sair
    mov ah, 2
    mov dh, 14     ; Uma linha abaixo
    mov dl, 10
    int 10h
    mov ah, 9
    mov dx, exit_msg
    int 21h

wait_difficulty:
    mov ah, 0
    int 16h
    
    cmp al, '3'
    je start_game
    cmp al, 27      ; ESC para sair
    je exit_game
    jmp wait_difficulty

start_game:
    mov byte [difficulty], 3    ; Usar configurações do modo difícil
    mov word [base_speed], 7    
    mov word [obstacle_speed], 7   
    mov word [speed_interval], 100
    mov byte [sky_active], 1    ; Ativar obstáculos no céu
    call init_game
    ret

main_loop:
    cmp byte [game_over], 1
    je game_over_screen
    call process_input
    call update_game
    call render
    call draw_score
    mov cx, 1      ; Reduzido o delay para 1
    call delay_loop
    jmp main_loop

game_over_screen:
    mov ax, [score]
    cmp ax, [high_score]
    jle .skip_high_score
    mov [high_score], ax
.skip_high_score:
    mov ah, 2
    mov bh, 0
    mov dh, 10
    mov dl, 5
    int 10h
    mov ah, 9
    mov dx, game_over_msg
    int 21h
wait_restart:
    mov ah, 1
    int 16h
    jz wait_restart
    mov ah, 0
    int 16h
    cmp al, ' '
    jne wait_restart
    call show_difficulty_select
    jmp main_loop

exit_game:
    ; Limpar a tela antes de sair
    mov ax, 0003h
    int 10h
    
    ; Sair para o DOS com código de saída 0
    mov ax, 4C00h
    int 21h

init_game:
    mov ax, 0013h
    int 10h
    mov word [player_y], 134
    mov word [player_vy], 0
    mov byte [is_jumping], 0
    mov word [score], 0
    mov word [obstacle_x], 320
    mov word [sky_obstacle_x], 480  ; Iniciar fora da tela
    mov byte [game_over], 0
    mov word [speed_timer], 0
    mov word [time_alive], 0     ; Resetar contador de tempo vivo
    mov word [last_boost_time], 0  ; Resetar tempo do último boost
    mov byte [speed_boosted], 0  ; Resetar flag de boost
    mov byte [speed_mult], 1     ; Resetar multiplicador de velocidade
    
    ; Configurar obstáculos baseado na dificuldade
    mov al, [difficulty]
    cmp al, 1
    je .easy_setup
    cmp al, 2
    je .medium_setup
    
.hard_setup:
    mov word [obstacle_width], 16
    mov byte [sky_active], 1    ; Ativar obstáculos do céu no modo difícil
    jmp .done_init

.medium_setup:
    mov word [obstacle_width], 16
    jmp .done_init

.easy_setup:
    mov word [obstacle_width], 16

.done_init:
    ret

; Função para tocar som
play_sound:
    push ax
    push bx
    push cx
    push dx
    
    mov al, 182
    out 43h, al
    mov ax, bx    ; Frequência em bx
    out 42h, al
    mov al, ah
    out 42h, al
    
    in al, 61h
    or al, 3
    out 61h, al
    
    mov cx, dx    ; Duração em dx
.delay:
    push cx
    mov cx, 100
.delay_loop:
    loop .delay_loop
    pop cx
    loop .delay
    
    in al, 61h
    and al, 0FCh
    out 61h, al
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

process_input:
    mov ah, 1
    int 16h
    jz no_key_pressed
    mov ah, 0
    int 16h
    
    cmp al, ' '
    jne check_escape
    
    ; Verificar se pode pular
    cmp byte [is_jumping], 0
    je do_first_jump
    
    ; Verificar se pode fazer pulo duplo
    cmp byte [can_double_jump], 1
    je do_double_jump
    jmp check_escape

do_first_jump:
    mov byte [is_jumping], 1
    mov ax, [jump_strength]
    mov [player_vy], ax
    ; Som de pulo
    mov bx, 1000
    mov dx, 100
    call play_sound
    jmp check_escape

do_double_jump:
    mov byte [can_double_jump], 0
    mov ax, [jump_strength]
    mov [player_vy], ax
    ; Som de pulo duplo (frequência mais alta)
    mov bx, 1200
    mov dx, 100
    call play_sound
    jmp check_escape

check_escape:
    cmp al, 27
    je exit_game
no_key_pressed:
    ret

update_game:
    ; Incrementar contador de tempo vivo
    inc word [time_alive]
    
    ; Verificar se passou 10 segundos desde o último boost (para todos os níveis)
    mov ax, [time_alive]
    sub ax, [last_boost_time]
    cmp ax, SPEED_UP_TIME
    jl .normal_update
    
    ; Aumentar velocidade a cada 10 segundos
    mov ax, [time_alive]
    mov [last_boost_time], ax    ; Atualizar tempo do último boost
    
    ; Verificar se já atingiu a velocidade máxima
    mov ax, [obstacle_speed]
    cmp ax, MAX_SPEED
    jge .normal_update
    
    ; Aumentar velocidade baseado na dificuldade
    mov al, [difficulty]
    cmp al, 1
    je .boost_easy
    cmp al, 2
    je .boost_medium
    
.boost_hard:
    add word [obstacle_speed], 2  ; Modo difícil: +2 velocidade
    jmp .after_boost

.boost_medium:
    add word [obstacle_speed], 1  ; Modo médio: +1 velocidade
    jmp .after_boost

.boost_easy:
    inc word [obstacle_speed]     ; Modo fácil: +1 velocidade a cada 2 boosts
    mov ax, [time_alive]
    and ax, 1                     ; Verificar se é boost par
    jnz .after_boost             ; Se ímpar, não aumenta

.after_boost:
    ; Ajustar intervalo de velocidade baseado na dificuldade
    mov al, [difficulty]
    cmp al, 1
    je .set_easy_interval
    cmp al, 2
    je .set_medium_interval
    
    mov word [speed_interval], 50  ; Difícil
    jmp .update_multiplier
    
.set_easy_interval:
    mov word [speed_interval], 150 ; Fácil
    jmp .update_multiplier
    
.set_medium_interval:
    mov word [speed_interval], 100 ; Médio
    
.update_multiplier:
    ; Incrementar multiplicador (com limite de 9)
    mov al, [speed_mult]
    cmp al, 9
    jge .play_sound
    inc byte [speed_mult]        ; Incrementar multiplicador

.play_sound:
    ; Som de aumento de velocidade (diferente para cada nível)
    mov al, [difficulty]
    cmp al, 1
    je .easy_sound
    cmp al, 2
    je .medium_sound
    
    ; Som difícil
    mov bx, 2500
    jmp .do_sound
    
.medium_sound:
    mov bx, 2000
    jmp .do_sound
    
.easy_sound:
    mov bx, 1500
    
.do_sound:
    mov dx, 200
    call play_sound

.normal_update:
    ; Atualizar posição do jogador
    cmp byte [is_jumping], 1
    jne update_obstacle
    mov ax, [player_vy]
    add [player_y], ax
    mov ax, [gravity]
    add [player_vy], ax
    mov ax, [player_y]
    cmp ax, 134
    jle update_obstacle
    mov word [player_y], 134
    mov byte [is_jumping], 0
    mov byte [can_double_jump], 1  ; Resetar pulo duplo ao tocar o chão
    mov word [player_vy], 0

update_obstacle:
    ; Mover obstáculo do chão
    mov ax, [obstacle_x]
    sub ax, [obstacle_speed]
    mov [obstacle_x], ax
    
    ; Verificar se o obstáculo saiu da tela
    cmp ax, -16
    jg .check_sky_obstacle
    mov word [obstacle_x], 320
    
    ; Som ao passar obstáculo
    mov bx, 2000
    mov dx, 150
    call play_sound
    
    ; Pontuação baseada na dificuldade
    mov al, [difficulty]
    cmp al, 1
    je .easy_score
    cmp al, 2
    je .medium_score
    
.hard_score:
    add word [score], 30
    jmp .check_sky_obstacle
.medium_score:
    add word [score], 20
    jmp .check_sky_obstacle
.easy_score:
    add word [score], 10

.check_sky_obstacle:
    ; Se não estiver no modo difícil, pular
    cmp byte [difficulty], 3
    jne .continue_update
    
    ; Mover obstáculo do céu
    mov ax, [sky_obstacle_x]
    sub ax, [obstacle_speed]
    mov [sky_obstacle_x], ax
    
    ; Verificar se o obstáculo do céu saiu da tela
    cmp ax, -16
    jg .continue_update
    mov word [sky_obstacle_x], 320
    
    ; Som ao passar obstáculo do céu
    mov bx, 2000
    mov dx, 150
    call play_sound
    add word [score], 30

.continue_update:
    ; Verificar colisões
    call check_collision
    jmp update_done

check_collision:
    ; Ajustar a caixa de colisão baseado na velocidade
    mov ax, [obstacle_speed]
    shr ax, 1                   ; Dividir por 2 para ter uma margem mais generosa
    mov cx, ax                  ; Guardar o ajuste em cx
    
    ; Verificar colisão com obstáculo do chão
    mov ax, [player_x]
    add ax, 6                   ; Margem mais generosa para o jogador
    mov bx, [obstacle_x]
    sub bx, cx                  ; Ajustar posição do obstáculo baseado na velocidade
    cmp ax, bx
    jl .check_sky_collision

    mov ax, [player_x]
    add ax, BLOCK_SIZE
    sub ax, 6                   ; Margem mais generosa para o jogador
    mov bx, [obstacle_x]
    add bx, [obstacle_width]
    add bx, cx                  ; Ajustar largura do obstáculo baseado na velocidade
    cmp ax, bx
    jg .check_sky_collision

    mov ax, [player_y]
    add ax, 4
    mov bx, [obstacle_y]
    cmp ax, bx
    jl .check_sky_collision

    mov ax, [player_y]
    add ax, BLOCK_SIZE
    sub ax, 4
    mov bx, [obstacle_y]
    add bx, [obstacle_height]
    cmp ax, bx
    jg .check_sky_collision

    ; Colisão detectada com obstáculo do chão
    mov byte [game_over], 1
    mov bx, 500
    mov dx, 300
    call play_sound
    ret

.check_sky_collision:
    ; Se não estiver no modo difícil ou obstáculo do céu não estiver ativo, sair
    cmp byte [difficulty], 3
    jne .no_collision
    cmp byte [sky_active], 0
    je .no_collision

    ; Verificar colisão com obstáculo do céu
    mov ax, [player_x]
    add ax, 6                   ; Margem mais generosa para o jogador
    mov bx, [sky_obstacle_x]
    sub bx, cx                  ; Ajustar posição do obstáculo baseado na velocidade
    cmp ax, bx
    jl .no_collision

    mov ax, [player_x]
    add ax, BLOCK_SIZE
    sub ax, 6                   ; Margem mais generosa para o jogador
    mov bx, [sky_obstacle_x]
    add bx, [obstacle_width]
    add bx, cx                  ; Ajustar largura do obstáculo baseado na velocidade
    cmp ax, bx
    jg .no_collision

    mov ax, [player_y]
    add ax, 4
    mov bx, [sky_obstacle_y]
    cmp ax, bx
    jl .no_collision

    mov ax, [player_y]
    add ax, BLOCK_SIZE
    sub ax, 4
    mov bx, [sky_obstacle_y]
    add bx, [obstacle_height]
    cmp ax, bx
    jg .no_collision

    ; Colisão detectada com obstáculo do céu
    mov byte [game_over], 1
    mov bx, 500
    mov dx, 300
    call play_sound

.no_collision:
    ret

update_done:
    ret

render:
    ; Esperar pelo retrace vertical antes de qualquer operação de vídeo
    mov dx, 03DAh
.wait1:
    in al, dx
    and al, 8
    jnz .wait1
.wait2:
    in al, dx
    and al, 8
    jz .wait2

    ; Configurar segmento de vídeo
    mov ax, 0A000h
    mov es, ax
    
    ; Limpar tela com cor do céu (mais eficiente)
    xor di, di
    mov cx, GROUND_HEIGHT * SCREEN_WIDTH
    mov al, 1      ; Azul escuro para o céu
    rep stosb

    ; Desenhar chão (mais eficiente)
    mov cx, SCREEN_WIDTH
    mov al, 6      ; Marrom
    rep stosb
    
    ; Desenhar linha de textura do chão
    mov cx, SCREEN_WIDTH
    mov al, 7      ; Cinza
    rep stosb

    ; Desenhar obstáculo do chão
    mov ax, [obstacle_y]
    mov dx, SCREEN_WIDTH
    mul dx
    add ax, [obstacle_x]
    mov di, ax
    
    mov dx, [obstacle_height]
.draw_obstacle:
    push dx
    mov cx, [obstacle_width]
    mov al, 4      ; Vermelho
    rep stosb
    pop dx
    add di, SCREEN_WIDTH
    sub di, [obstacle_width]
    dec dx
    jnz .draw_obstacle

    ; Desenhar obstáculo do céu no modo difícil
    cmp byte [difficulty], 3
    jne .draw_player
    cmp byte [sky_active], 0
    je .draw_player

    mov ax, [sky_obstacle_y]
    mov dx, SCREEN_WIDTH
    mul dx
    add ax, [sky_obstacle_x]
    mov di, ax
    
    mov dx, [obstacle_height]
.draw_sky_obstacle:
    push dx
    mov cx, [obstacle_width]
    mov al, 12     ; Vermelho claro
    rep stosb
    pop dx
    add di, SCREEN_WIDTH
    sub di, [obstacle_width]
    dec dx
    jnz .draw_sky_obstacle

    ; Desenhar jogador
    mov ax, [player_y]
    mov dx, SCREEN_WIDTH
    mul dx
    add ax, [player_x]
    mov di, ax

    ; Desenhar corpo do jogador (mais eficiente)
    mov dx, 16     ; Altura total do jogador
.draw_player:
    push dx
    mov cx, 6      ; Largura máxima do jogador
    mov al, 9      ; Azul claro
    rep stosb
    pop dx
    add di, SCREEN_WIDTH
    sub di, 6
    dec dx
    jnz .draw_player

    ; Não precisamos esperar por outro retrace aqui
    ; pois já estamos sincronizados
    ret

draw_score:
    ; Desenhar "Score: "
    mov ah, 2
    mov bh, 0
    mov dh, 1      ; Linha 1
    mov dl, 1      ; Coluna 1
    int 10h
    mov ah, 9
    mov dx, score_msg
    int 21h

    ; Converter score atual
    mov ax, [score]
    call convert_number
    mov ah, 9
    mov dx, score_str
    int 21h

    ; Desenhar "High Score: "
    mov ah, 2
    mov dh, 1      ; Linha 1
    mov dl, 20     ; Coluna 20
    int 10h
    mov ah, 9
    mov dx, high_score_msg
    int 21h

    ; Converter high score
    mov ax, [high_score]
    call convert_number
    mov ah, 9
    mov dx, score_str
    int 21h

    ; Desenhar "Speed: "
    mov ah, 2
    mov dh, 2      ; Movido para linha 2
    mov dl, 1      ; Coluna 1
    int 10h
    mov ah, 9
    mov dx, speed_msg
    int 21h

    ; Mostrar multiplicador de velocidade
    mov di, speed_str
    mov al, [speed_mult]     ; Usar o multiplicador armazenado
    add al, '0'              ; Converter para ASCII
    mov [di], al            ; Armazenar dígito
    mov byte [di+1], '$'    ; Adicionar terminador
    
    ; Mostrar multiplicador
    mov ah, 9
    mov dx, speed_str
    int 21h
    
    ; Mostrar "x"
    mov ah, 9
    mov dx, speed_x_msg
    int 21h
    
    ret

; Nova função para converter número para string
convert_number:
    mov cx, 5          ; 5 dígitos
    mov di, score_str
    add di, 4          ; Começar do último dígito
    mov byte [di+1], '$' ; Adicionar terminador
.loop:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'        ; Converter para ASCII
    mov [di], dl       ; Armazenar dígito
    dec di             ; Mover para o próximo dígito
    loop .loop
    ret

delay_loop:
    push cx
    mov cx, 0FFFFh
.inner_loop:
    nop           ; Adicionar um pequeno delay
    nop
    loop .inner_loop
    pop cx
    dec cx
    jnz delay_loop
    ret 