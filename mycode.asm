data segment
    file db "d:\words.txt", 0
    file_code dw ?
    error_msg db "Error Input! Please press between 0 to 4!$"
    success_msg db "Success!  Press any to conitue...$"
    not_find_msg db "Can not find the word!  Press any to continue...$"
    search_like_msg db "Can not find the word!  But we found the related words for you:$"
    word_exist_msg db "The word has exist! Press any to continue...$"
    waiting_msg db " (please waiting patiently until the cursor beating...)$"
    str0 db "Dictionary$"
    str1 db "Press 0 for exit, 1 for search, 2 for input, 3 for modify, 4 for delete:$"
    str2 db "explain:$"
    str3 db "synonym:$"
    str4 db "antonym:$"
    str5 db "Thanks for your using!$"
    str6 db "Bye~$"
    fun1 db "search:$"
    fun2 db "input:$"
    fun3 db "modify$"
    fun4 db "delete:$"
    word db 128 dup(" ")
    words db 6400 dup(" ")  ;��ά���飬64��100�У�0-19�д�ŵ��ʣ�20-59��Ž��ͣ�60-79��Ž���ʣ�80-99��ŷ����
    cnt dw 0
    like_cnt dw 0
    now dw 0
    is_exist dw 0
    pos dw -1
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:

    mov ax, data
    mov ds, ax
    mov es, ax

;--------------------------------------------------�궨��--------------------------------------------------;
    
    scroll macro n, ulr, ulc, lrr, lrc, att           ;�������Ͼ�궨��
        mov ah, 6                                     ;�������Ͼ�
        mov al, n                                     ;N=�Ͼ�������N=0����
        mov ch, ulr                                   ;���Ͻ��к�
        mov cl, ulc                                   ;���Ͻ��к�
        mov dh, lrr                                   ;���½��к�
        mov dl, lrc                                   ;���½��к�
        mov bh, att                                   ;����������
        int 10h
    endm
   
    curse macro cury, curx
        mov ah, 2                                     ;�ù��λ��
        mov dh, cury                                  ;�к�
        mov dl, curx                                  ;�к�
        mov bh, 0                                     ;��ǰҳ
        int 10h
    endm

    input_word macro off, len                         ;���뵥�ʡ����͵�
        local next, for1, for2, for3, for4, for5, move, insert, out1, additional, exist, exit
        mov ah, 0ah                                   ;����
        lea dx, word
        int 21h
        mov ax, off
        cmp ax, 0
        jnz next
        call warning
        next:
        mov bl, off                               
        sub bl, 0                                     ;�ж��ǲ������뵥��
        jnz insert                                    ;������ֱ�Ӳ���
        cld                                           ;������Ҫ�ҵ����Ĳ��룬����ԭ����������ƶ�����λ��
        mov cx, cnt                                   ;�Ѵ洢�ĵ�������                            
        for1:                                      
            jcxz additional                                 
            push cx                                   ;�洢�Ѿ����ʵ��ڼ�������            
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100                             
            mul bl                                    ;��¼��cx-1(��Ϊ�±��0��ʼ)�����ʵ��׵�ַ 
            mov di, ax                            
            lea si, word[2]                           ;���ʵĵ�һ����ĸ��ַ
            mov cl, [si-1]                            ;�������ʵĳ���          
            for2:
                lodsb
                cmp al, words[di]                     ;�ӵ�һ����ĸ��ʼһ�αȽ�
                jb out1                               ;��Ϊ�ǴӺ���ǰ�Ƚϣ���������¼���Ĵ�С������ڲ�ѭ��
                cmp al, words[di]
                ja move                               ;���ڵ�ǰ�������ѭ�����в��루��Ϊ��һ���ж��Ѿ�ȷ��С�ں�һ���ʣ�,���ڵ�cx+1��words[cx]
                inc di
                loop for2                             ;���������ڲ�ѭ��
                cmp words[di], ' '                    ;word������ȫ��ͬ�����ж�words�Ƿ����
                jz exist
                out1:
                    pop cx
                    loop for1
                    push cx
                    jmp move
                additional:
                    push 0
                    jmp insert
                exist:
                    scroll 4, 5, 1, 9, 78, 71h        ;��������               
                    curse 7, 20
                    mov ah, 09h
                    lea dx, word_exist_msg
                    int 21h
                    mov ah, 0                         ;�ȴ�����
                    int 16h       
                    scroll 4, 5, 1, 9, 78, 71h            
                    curse 7, 4
                    mov ah, 09h
                    lea dx, str1
                    int 21h
                    mov is_exist, 1
                    jmp exit
                    
        move:
            std                                       ;si��di�ݼ�
            mov ax, cnt                               ;ȡ���ܹ���������
            xor bx, bx
            mov bl, 100
            mul bl                                    ;����ܹ������ֽ�
            lea bx, words                             ;ȡ��words��ַ
            add ax, bx                                ;���ϱ�ַ�õ����һ�����ʵĺ�һ�����ʵĵ�ַ
            dec ax                                    ;��һ�õ����һ�����ʵ����һ����ĸ
            mov si, ax
            add ax, 100                               ;ÿ����Ҫ�ƶ�100λ
            mov di, ax
            mov ax, cnt                               ;ȡ���ܹ���������
            pop cx                                    ;��ǰҪ���ڵڼ������ʺ���
            sub ax, cx                                ;����Ӧ���ƶ���������
            mov now, cx                               ;����һ��Ҫ�����ļ�¼�������Ա����insert
            xor bx, bx
            mov bl, 100 
            mul bl
            mov cx, ax                                ;��Ϊѭ������
            jcxz insert
            for3:
                lodsb                                 ;��si����ÿһλ�ȱ��浽al��
                stosb                                 ;�ٰ�al�ƶ���di��ָ
                loop for3                              
            insert:
                cld
                mov ax, now
                xor bx, bx
                mov bl, 100                            
                mul bl                                ;�������ַ����Ӧ�����Ŀ�ʼ�洢
                lea bx, words
                add ax, bx
                mov bx, off
                add ax, bx                            ;����ƫ����
                mov di, ax
                lea si, word[2]
                xor cx, cx
                mov cl, [si-1]
                mov ax, len
                sub ax, cx
                push ax 
                for4:
                    lodsb
                    stosb
                    loop for4
                pop cx
                for5:
                    mov al, ' '
                    stosb
                    loop for5
        exit:      
    endm
    
    modify_word macro off, len                        ;�޸ĵ��ʡ����͵�
        local for1, for2
        mov ah, 0ah                                   ;����
        lea dx, word
        int 21h
        cld 
        mov cx, now 
        mov ax, cx
        dec ax
        xor bx, bx
        mov bl, 100                            
        mul bl                                        ;�������ַ����Ӧ�����Ŀ�ʼ�޸�
        lea bx, words
        add ax, bx
        mov bx, off
        add ax, bx                                    ;����ƫ����
        mov di, ax
        lea si, word[2]
        xor cx, cx
        mov cl, [si-1]
        mov ax, len                                   ;����ʣ�¶����ַ���Ҫ��Ϊ��
        sub ax, cx
        push ax 
        for1:
            lodsb
            stosb
            loop for1
        pop cx
        for2:
            mov al, ' '
            stosb
            loop for2
    endm 
    
    delete_word macro                                 ;����pos��λ��ɾ������
        local for
        mov ax, pos                                   ;ɾ���ĸ�λ�õĵ���
        cld                                               
        dec ax
        xor bx, bx
        mov bl, 100
        mul bl                                        ;����ܹ������ֽ�
        lea bx, words                                 ;ȡ��words��ַ
        add ax, bx                                    ;���ϱ�ַ�õ�Ҫɾ���ĵ��ʵĵ�ַ
        mov di, ax
        add ax, 100                                   ;ÿ����Ҫ�ƶ�100λ
        mov si, ax
        mov ax, cnt                                   ;ȡ���ܹ���������
        mov cx, pos                                
        sub ax, cx                                    ;������������
        inc ax                                        ;����ʵ��Ҫ�ƶ��ĵ�������
        xor bx, bx
        mov bl, 100 
        mul bl
        mov cx, ax                                    ;��Ϊѭ������
        for:
            lodsb                                     ;��si����ÿһλ�ȱ��浽al��
            stosb                                     ;�ٰ�al�ƶ���di��ָ
            loop for   
    endm

;--------------------------------------------------������--------------------------------------------------;        
          
    import:                                           ;���ļ������ֵ�����
        ;mov ah, 3ch                                  ;�½��ļ�
        ;mov cx, 0
        ;lea dx, file                         
        ;int 21h        
        mov al, 0                                     ;�򿪷�ʽΪд
        mov ah, 3DH                                   ;���ļ�
        lea dx, file
        int 21h
        mov file_code, ax                             ;�����ļ���
        mov ah, 3FH                                   ;��ȡ�ļ�
        mov bx, file_code                             ;���ļ����Ŵ�����bx
        mov cx, 6400
        lea dx, words                                 ;���ݻ�������ַ 
        int 21h
        mov bl, 100 
        div bl                                        ;�������ȡ�˶��ٵ���
        mov cnt, ax      
        mov bx, file_code                             ;���ļ����Ŵ�����bx
        mov ah, 3EH                                   ;�ر��ļ�
        int 21h
               
    ui:                                               ;����ui����
        scroll 0, 0, 0, 24, 79, 02                    ;����
        scroll 25, 0, 0, 24, 79, 30h                  ;���ⴰ�ڣ���ɫ��
        scroll 23, 1, 1, 3, 78, 71h                   ;����
        scroll 23, 5, 1, 9, 78, 71h                   ;�����
        scroll 23, 11, 1, 12��78, 71h                 ;���Ͳ���ʾ������ɫ
        scroll 23, 13, 1, 15��78, 72h                 ;���Ͳ�
        scroll 23, 17, 1, 18��38, 71h                 ;��ײ���ʾ������ɫ
        scroll 23, 17, 40, 18��78, 71h                ;��ײ���ʾ������ɫ
        scroll 23, 19, 1, 23��38, 72h                 ;ͬ��ʲ�
        scroll 23, 19, 40, 23, 78, 72h                ;����ʲ�
    
    call init_str                                     ;��ʼ����ʾ����
    
    choose:
        mov ah, 0                                     ;����ѡ��
        int 16h                                           
        mov ah, 0eh                                   ;��ʾ������ַ�
        int 10h                                              
        cmp al, 48                                    ;ѡ��0,��ʾ�˳�
        jz export                               
        cmp al, 49                                    ;ѡ��1,��ʾ����
        jz search
        cmp al, 50                                    ;ѡ��2,��ʾ����
        jz input
        cmp al, 51                                    ;ѡ��3,��ʾ�޸�
        jz modify                                    
        cmp al, 52                                    ;ѡ��4,��ʾɾ��
        jz delete 
        scroll 4, 5, 1, 9, 78, 71h                    ;��������
        curse 7, 4  
        mov ah, 09h
        lea dx, error_msg                             ;����������ʾ
        int 21h                                      
        mov ah, 0
        int 16h
        curse 7, 4                                    ;��������
        mov ah, 09h                                  
        lea dx, str1
        int 21h
        jmp choose
    search:                                           ;����
        lea dx, fun1                                 
        call funstr                                   ;���������ʾ��ǰִ�еĲ���Ϊ����
        curse 7, 12                                  
        call search_exact_like
        search_exit:
            jmp choose
    input:                                             ;����
        mov is_exist, 0
        lea dx, fun2                          
        call funstr                                   ;���������ʾ��ǰִ�еĲ���Ϊ����
        curse 7, 12                                    
        input_word 0, 20                              ;���뵥��
        mov ax, is_exist
        cmp ax, 1
        jz input_exit                                 
        inc cnt                                       ;��������+1
        curse 13, 12
        input_word 20, 40                             ;����ע��
        curse 20, 12                                
        input_word 60, 20                             ;����ͬ���
        curse 20, 51
        input_word 80, 20                             ;���뷴���
        call clear                                    ;��ս��
        input_exit:
            jmp choose
    modify:                                           ;�޸ĵ���
        lea dx, fun3                                   
        call funstr                                   ;���������ʾ��ǰִ�еĲ���Ϊ�޸�
        curse 7, 12
        call find                                     ;���ò��Һ��������ص���λ�õ�pos�����Ҳ����������ʾ��Ϣ������posΪ-1
        mov cx, pos                                 
        cmp cx, -1                                    ;-1������ѯ�������˳�
        jz modify_exit                        
        mov now, cx
        curse 13, 12
        modify_word 20, 40                            ;�޸Ľ��ͣ�ƫ�Ƶ�ַΪ20������40
        curse 20, 12
        modify_word 60, 20                            ;�޸�ͬ��ʣ�ƫ�Ƶ�ַΪ60������20
        curse 20, 51
        modify_word 80, 20                            ;�޸ķ���ʣ�ƫ�Ƶ�ַΪ80������20
        call clear
        modify_exit:
            jmp choose 
    delete:                                           ;ɾ������
        lea dx, fun4                                 
        call funstr                                   ;���������ʾ��ǰִ�еĲ���Ϊɾ��
        curse 7, 12                                   
        call find                                     ;���ò��Һ��������ص���λ�õ�pos�����Ҳ����������ʾ��Ϣ������posΪ-1
        mov cx, pos
        cmp cx, -1                                    ;-1������ѯ�������˳�
        jz delete_exit
        delete_word                                   ;����posλ��ɾ������
        dec cnt                                       ;��������-1
        call clear                                  
        delete_exit:
            jmp choose        
                 
    export:                                           ;�����������ļ�
        lea dx, file         
        mov al, 1                                     ;�򿪷�ʽΪд
        mov ah, 3DH                                   ;���ļ�
        int 21h
        mov file_code, ax                             ;�����ļ���
        mov ax, cnt                                   ;д����ֽ���
        mov bl, 100
        mul bl
        mov cx, ax
        mov ah, 40H                                   ;д���ļ�
        mov bx, file_code                             ;���ļ����Ŵ�����bx
        lea dx, words                                 ;���ݻ�������ַ 
        int 21h       
        mov bx, file_code                             ;���ļ����Ŵ�����bx
        mov ah, 3EH                                   ;�ر��ļ�
        int 21h
         
    exit:        
        call exit_str                                 ;�˳���Ϣ
        mov ax, 4c00h                                 ;��������
        int 21h  
    
;--------------------------------------------------��������--------------------------------------------------;
   
    init_str proc                                     ;��ʾ�����ַ���
        push ax
        push dx
        curse 2, 35
        mov ah, 09h                                   ;��ʾ�ֵ�
        lea dx, str0                                
        int 21h
        curse 12, 4
        mov ah, 09h                                   ;��ʾע��
        lea dx, str2
        int 21h
        curse 18, 4
        mov ah, 09h                                   ;��ʾͬ���
        lea dx, str3
        int 21h
        curse 18, 43
        mov ah, 09h                                   ;��ʾ�����
        lea dx, str4
        int 21h
        curse 7, 4     
        mov ah, 09h                                   ;��ʾѡ����Ϣ
        lea dx, str1
        int 21h        
        pop dx
        pop ax
        ret
    init_str endp
    
    exit_str proc                                     ;����ҳ��
        push dx
        push ax
        scroll 0, 1, 1, 23, 78, 72h                   ;����
        curse 11, 28
        mov ah, 09h
        lea dx, str5
        int 21h
        scroll 1, 1, 1, 23, 78, 72h                   ;�Ͼ�һ��
        curse 12, 38
        mov ah, 09h
        lea dx, str6
        int 21h
        mov ah, 0                                     ;�ȴ�����
        int 16h       
        pop ax
        pop dx
        ret       
    exit_str endp    
    
    clear proc
        push ax
        push bx
        push cx
        push dx
        scroll 4, 5, 1, 9, 78, 71h                    ;��������
        scroll 3, 13, 1, 15��78, 72h                  ;���Ͳ����
        scroll 4, 19, 1, 23��38, 72h                  ;ͬ��ʲ����
        scroll 4, 19, 40, 23, 78, 72h                 ;����ʲ����
        curse 7, 23
        mov ah, 09h                                   ;�������ʾ�ɹ���Ϣ
        lea dx, success_msg
        int 21h
        mov ah, 0                                     ;�ȴ�����
        int 16h                                      
        scroll 4, 5, 1, 9, 78, 71h                    ;��������
        curse 7, 4     
        mov ah, 09h
        lea dx, str1                                  ;�������ʾѡ����Ϣ
        int 21h
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    clear endp
    
    funstr proc                                       ;�����ǰ������ʾ�ַ�
        push ax
        push bx
        push cx
        push dx
        scroll 23, 5, 1, 6, 78, 71h                   ;�������ʾ������ɫ
        scroll 23, 7, 1, 9, 78, 72h                   ;�����
        curse 6, 4                                 
        mov ah, 09h
        pop dx        
        int 21h
        pop cx
        pop bx
        pop ax
        ret
    funstr endp  
    
    find proc                                         ;��ȷѰ�ҵ���
        push dx
        push cx
        push bx                                      
        push ax
        mov ah, 0ah                                   ;����
        lea dx, word
        int 21h
        call warning
        cld                                       
        mov cx, cnt                                   ;�Ѵ洢�ĵ�������
        jcxz notequal_find                            ;cxΪ0��϶��Ҳ�������
        for1_find:                                 
            push cx                                   ;�洢�Ѿ����ʵ��ڼ�������
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100
            mul bl                                    ;��¼��cx-1�����ʵ��׵�ַ 
            mov di, ax
            dec di                                    ;����ͳһ��1,����������ǰ��1
            xor cx, cx                                       
            lea si, word[2]                           ;���ʵĵ�һ����ĸ��ַ
            mov cl, [si-1]                            ;�������ʵĳ���          
            for2_find:
                inc di
                lodsb
                cmp al, words[di]
                jne outfor_find                       ;��ǰ���ʳ�����ĸ�����
                loop for2_find                        ;��ĸ��ȼ��������ж�
                inc di                                ;word�����ж��꣬ȫ����ͬ�����е��˴�
                cmp words[di], ' '                    ;�ж�words�����Ƿ����
                jnz outfor_find                       ;û�н���������ж�
                pop cx                                ;������˵���ҵ�ƥ�䵥��
                mov pos, cx
                jmp find_exit                         
                outfor_find:                          ;���ֲ��������ѭ���ж���һ������
                    pop cx                            
                    loop for1_find
            notequal_find:                            ;���е��˴�˵��ƥ�䲻������
                mov pos, -1
                scroll 4, 5, 1, 9, 78, 71h            ;�����               
                curse 7, 15
                mov ah, 09h
                lea dx, not_find_msg
                int 21h
                mov ah, 0                             ;�ȴ�����
                int 16h       
                scroll 4, 5, 1, 9, 78, 71h            ;�����
                curse 7, 4                          
                mov ah, 09h
                lea dx, str1
                int 21h
            find_exit:                               
                pop ax
                pop bx
                pop cx
                pop dx
                ret
        find endp  
                    
    search_exact_like proc
        push ax
        push bx
        push cx
        push dx
        mov like_cnt, 0                               ;ģ����ѯ�������Ϊ0
        mov ah, 0ah                                   ;����
        lea dx, word                                  
        int 21h
        call warning                                  ;������ʾ��Ϣ
        cld                                       
        mov cx, cnt                                   ;�Ѵ洢�ĵ�������
        jcxz notequal_search                          ;cxΪ0��϶��Ҳ�������
        for1_search:                                 
            push cx                                   ;�洢�Ѿ����ʵ��ڼ�������
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100
            mul bl                                    ;��¼��cx-1�����ʵ��׵�ַ 
            mov di, ax
            dec di                                    ;����ͳһ��1,����������ǰ��1
            xor cx, cx                                       
            lea si, word[2]                           ;���ʵĵ�һ����ĸ��ַ
            mov cl, [si-1]                            ;�������ʵĳ���          
            for2_search:
                inc di
                lodsb
                cmp al, words[di]
                jne outfor_search                     ;��ǰ���ʳ�����ĸ�����
                loop for2_search                      ;��ĸ��ȼ��������ж�
                inc di                                ;word�����ж��꣬ȫ����ͬ�����е��˴�
                cmp words[di], ' '                    ;�ж�words�����Ƿ����
                jz search_exact                       ;������ȷ������
                pop cx
                push cx
                mov pos, cx
                inc like_cnt                          ;����ģ����ѯ�Ľ�������������һ�����ʵĲ�ѯ   
                outfor_search:                        ;���ֲ��������ѭ���ж���һ������
                    pop cx                            
                    loop for1_search
                cmp like_cnt, 0
                jnz search_like                       ;like_cnt��Ϊ0�����ģ����ѯ���������������Ҳ�������
            notequal_search:                          ;���е��˴�˵��ƥ�䲻������
                scroll 4, 5, 1, 9, 78, 71h            ;�����               
                curse 7, 15                          
                mov ah, 09h
                lea dx, not_find_msg
                int 21h
                mov ah, 0                             ;�ȴ�����
                int 16h       
                scroll 4, 5, 1, 9, 78, 71h            ;�����
                curse 7, 4                        
                mov ah, 09h
                lea dx, str1
                int 21h
                jmp search_exact_like_exit
            search_exact:
                cld
                pop ax
                dec ax
                xor bx, bx
                mov bl, 100                            
                mul bl                                ;�������ַ����Ӧ�����Ŀ�ʼ���
                lea bx, words
                add ax, bx                            ;��������λ��
                add ax, 20                            ;��words[20]��ʼ
                mov si, ax                                               
                lea di, word
                mov cx, 40
                for_explain:                          ;�������
                    lodsb
                    stosb
                    loop for_explain
                curse 13, 12
                mov word[39], '$'
                mov ah, 09h
                lea dx, word
                int 21h
                lea di, word
                mov cx, 20
                for_synonym:                          ;���ͬ���
                    lodsb                           
                    stosb
                    loop for_synonym 
                curse 20, 12
                mov word[19], '$'
                mov ah, 09h
                lea dx, word
                int 21h
                lea di, word 
                mov cx, 20
                for_antonym:                          ;��������
                    lodsb
                    stosb
                    loop for_antonym
                curse 20, 51  
                mov word[19], '$'
                mov ah, 09h
                lea dx, word
                int 21h
                mov ah, 0                             ;�ȴ�����
                int 16h                             
                call clear
                jmp search_exact_like_exit
            search_like:
                scroll 23, 11, 1, 13��78, 71h         ;����ui
                scroll 23, 14, 1, 23��78, 72h         ;����ui
                curse 13, 7
                mov ah, 09h
                lea dx, search_like_msg
                int 21h
                mov cx, like_cnt
                search_like_for1:
                    push cx
                    mov ax, pos
                    inc pos                           ;ÿ����һ��pos������һ������
                    dec ax
                    xor bx, bx
                    mov bl, 100                            
                    mul bl                            ;�������ַ����Ӧ�����Ŀ�ʼ���
                    lea bx, words
                    add ax, bx                        ;��������λ��
                    mov si, ax                                   
                    lea di, word
                    mov cx, 20
                    search_like_for2:
                        lodsb
                        stosb
                        loop search_like_for2
                    curse 20, 14
                    mov word[19], '$'
                    mov ah, 09h
                    lea dx, word                                                                        
                    int 21h
                    scroll 1, 15, 1, 21��78, 72h
                    pop cx
                    dec cx
                    cmp cx, 0
                    jnz search_like_for1
                    mov ah, 0                         ;�ȴ�����
                    int 16h                     
                    scroll 4, 5, 1, 9, 78, 71h        ;��������
                    scroll 13, 11, 1, 23, 78, 30h     ;������Ʋ��ҽ�� 
                    ;������Ͳ��ͬ�塢�����
                    scroll 23, 11, 1, 12��78, 71h     ;���Ͳ���ʾ������ɫ
                    scroll 23, 13, 1, 15��78, 72h     ;���Ͳ�
                    scroll 23, 17, 1, 18��38, 71h     ;��ײ���ʾ������ɫ
                    scroll 23, 17, 40, 18��78, 71h    ;��ײ���ʾ������ɫ
                    scroll 23, 19, 1, 23��38, 72h     ;ͬ��ʲ�
                    scroll 23, 19, 40, 23, 78, 72h    ;����ʲ�
                    curse 12, 4
                    mov ah, 09h
                    lea dx, str2
                    int 21h
                    curse 18, 4
                    mov ah, 09h
                    lea dx, str3
                    int 21h
                    curse 18, 43
                    mov ah, 09h
                    lea dx, str4
                    int 21h
                    curse 7, 4     
                    mov ah, 09h
                    lea dx, str1
                    int 21h
                    curse 7, 4     
                    mov ah, 09h
                    lea dx, str1
                    int 21h
                    call init_str                     ;��ʼ������
        search_exact_like_exit:    
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    search_exact_like endp 
    
    warning proc                                      ;�ȴ���ʾ
        push dx
        push cx
        push bx
        push ax
        mov ah, 09h
        lea dx, waiting_msg
        int 21h
        pop ax
        pop bx
        pop cx
        pop dx
        ret
    warning endp    
      
ends

end start