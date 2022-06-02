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
    words db 6400 dup(" ")  ;二维数组，64行100列，0-19列存放单词，20-59存放解释，60-79存放近义词，80-99存放反义词
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

;--------------------------------------------------宏定义--------------------------------------------------;
    
    scroll macro n, ulr, ulc, lrr, lrc, att           ;清屏或上卷宏定义
        mov ah, 6                                     ;清屏或上卷
        mov al, n                                     ;N=上卷行数，N=0清屏
        mov ch, ulr                                   ;左上角行号
        mov cl, ulc                                   ;左上角列号
        mov dh, lrr                                   ;右下角行号
        mov dl, lrc                                   ;右下角列号
        mov bh, att                                   ;卷入行属性
        int 10h
    endm
   
    curse macro cury, curx
        mov ah, 2                                     ;置光标位置
        mov dh, cury                                  ;行号
        mov dl, curx                                  ;列号
        mov bh, 0                                     ;当前页
        int 10h
    endm

    input_word macro off, len                         ;读入单词、解释等
        local next, for1, for2, for3, for4, for5, move, insert, out1, additional, exist, exit
        mov ah, 0ah                                   ;输入
        lea dx, word
        int 21h
        mov ax, off
        cmp ax, 0
        jnz next
        call warning
        next:
        mov bl, off                               
        sub bl, 0                                     ;判断是不是输入单词
        jnz insert                                    ;不是则直接插入
        cld                                           ;是则需要找到在哪插入，并把原本单词向后移动留出位置
        mov cx, cnt                                   ;已存储的单词数量                            
        for1:                                      
            jcxz additional                                 
            push cx                                   ;存储已经访问到第几个单词            
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100                             
            mul bl                                    ;记录第cx-1(因为下标从0开始)个单词的首地址 
            mov di, ax                            
            lea si, word[2]                           ;单词的第一个字母地址
            mov cl, [si-1]                            ;新增单词的长度          
            for2:
                lodsb
                cmp al, words[di]                     ;从第一个字母开始一次比较
                jb out1                               ;因为是从后往前比较，所以如果新加入的词小则结束内层循环
                cmp al, words[di]
                ja move                               ;大于当前词则结束循环进行插入（因为上一次判断已经确定小于后一个词）,插在第cx+1即words[cx]
                inc di
                loop for2                             ;相等则继续内层循环
                cmp words[di], ' '                    ;word部分完全相同，则判断words是否结束
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
                    scroll 4, 5, 1, 9, 78, 71h        ;输入层清空               
                    curse 7, 20
                    mov ah, 09h
                    lea dx, word_exist_msg
                    int 21h
                    mov ah, 0                         ;等待输入
                    int 16h       
                    scroll 4, 5, 1, 9, 78, 71h            
                    curse 7, 4
                    mov ah, 09h
                    lea dx, str1
                    int 21h
                    mov is_exist, 1
                    jmp exit
                    
        move:
            std                                       ;si和di递减
            mov ax, cnt                               ;取出总共几个单词
            xor bx, bx
            mov bl, 100
            mul bl                                    ;算出总共几个字节
            lea bx, words                             ;取出words基址
            add ax, bx                                ;加上变址得到最后一个单词的后一个单词的地址
            dec ax                                    ;减一得到最后一个单词的最后一个字母
            mov si, ax
            add ax, 100                               ;每个都要移动100位
            mov di, ax
            mov ax, cnt                               ;取出总共几个单词
            pop cx                                    ;当前要插在第几个单词后面
            sub ax, cx                                ;计算应该移动几个单词
            mov now, cx                               ;将这一次要插在哪记录起来，以便后面insert
            xor bx, bx
            mov bl, 100 
            mul bl
            mov cx, ax                                ;作为循环次数
            jcxz insert
            for3:
                lodsb                                 ;将si（即每一位先保存到al）
                stosb                                 ;再把al移动到di所指
                loop for3                              
            insert:
                cld
                mov ax, now
                xor bx, bx
                mov bl, 100                            
                mul bl                                ;计算出变址，即应该在哪开始存储
                lea bx, words
                add ax, bx
                mov bx, off
                add ax, bx                            ;加上偏移量
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
    
    modify_word macro off, len                        ;修改单词、解释等
        local for1, for2
        mov ah, 0ah                                   ;输入
        lea dx, word
        int 21h
        cld 
        mov cx, now 
        mov ax, cx
        dec ax
        xor bx, bx
        mov bl, 100                            
        mul bl                                        ;计算出变址，即应该在哪开始修改
        lea bx, words
        add ax, bx
        mov bx, off
        add ax, bx                                    ;加上偏移量
        mov di, ax
        lea si, word[2]
        xor cx, cx
        mov cl, [si-1]
        mov ax, len                                   ;计算剩下多少字符需要置为空
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
    
    delete_word macro                                 ;根据pos的位置删除单词
        local for
        mov ax, pos                                   ;删除哪个位置的单词
        cld                                               
        dec ax
        xor bx, bx
        mov bl, 100
        mul bl                                        ;算出总共几个字节
        lea bx, words                                 ;取出words基址
        add ax, bx                                    ;加上变址得到要删除的单词的地址
        mov di, ax
        add ax, 100                                   ;每个都要移动100位
        mov si, ax
        mov ax, cnt                                   ;取出总共几个单词
        mov cx, pos                                
        sub ax, cx                                    ;计算相差几个单词
        inc ax                                        ;计算实际要移动的单词数量
        xor bx, bx
        mov bl, 100 
        mul bl
        mov cx, ax                                    ;作为循环次数
        for:
            lodsb                                     ;将si（即每一位先保存到al）
            stosb                                     ;再把al移动到di所指
            loop for   
    endm

;--------------------------------------------------主程序--------------------------------------------------;        
          
    import:                                           ;从文件导入字典数据
        ;mov ah, 3ch                                  ;新建文件
        ;mov cx, 0
        ;lea dx, file                         
        ;int 21h        
        mov al, 0                                     ;打开方式为写
        mov ah, 3DH                                   ;打开文件
        lea dx, file
        int 21h
        mov file_code, ax                             ;保存文件码
        mov ah, 3FH                                   ;读取文件
        mov bx, file_code                             ;将文件代号传送至bx
        mov cx, 6400
        lea dx, words                                 ;数据缓冲区地址 
        int 21h
        mov bl, 100 
        div bl                                        ;计算出读取了多少单词
        mov cnt, ax      
        mov bx, file_code                             ;将文件代号传送至bx
        mov ah, 3EH                                   ;关闭文件
        int 21h
               
    ui:                                               ;定义ui界面
        scroll 0, 0, 0, 24, 79, 02                    ;清屏
        scroll 25, 0, 0, 24, 79, 30h                  ;开外窗口，青色底
        scroll 23, 1, 1, 3, 78, 71h                   ;最顶层框
        scroll 23, 5, 1, 9, 78, 71h                   ;输入层
        scroll 23, 11, 1, 12，78, 71h                 ;解释层提示字体蓝色
        scroll 23, 13, 1, 15，78, 72h                 ;解释层
        scroll 23, 17, 1, 18，38, 71h                 ;最底层提示字体蓝色
        scroll 23, 17, 40, 18，78, 71h                ;最底层提示字体蓝色
        scroll 23, 19, 1, 23，38, 72h                 ;同义词层
        scroll 23, 19, 40, 23, 78, 72h                ;反义词层
    
    call init_str                                     ;初始化提示文字
    
    choose:
        mov ah, 0                                     ;读入选择
        int 16h                                           
        mov ah, 0eh                                   ;显示输入的字符
        int 10h                                              
        cmp al, 48                                    ;选择0,表示退出
        jz export                               
        cmp al, 49                                    ;选择1,表示查找
        jz search
        cmp al, 50                                    ;选择2,表示插入
        jz input
        cmp al, 51                                    ;选择3,表示修改
        jz modify                                    
        cmp al, 52                                    ;选择4,表示删除
        jz delete 
        scroll 4, 5, 1, 9, 78, 71h                    ;输入层清空
        curse 7, 4  
        mov ah, 09h
        lea dx, error_msg                             ;错误输入提示
        int 21h                                      
        mov ah, 0
        int 16h
        curse 7, 4                                    ;重新输入
        mov ah, 09h                                  
        lea dx, str1
        int 21h
        jmp choose
    search:                                           ;查找
        lea dx, fun1                                 
        call funstr                                   ;在输入层显示当前执行的操作为查找
        curse 7, 12                                  
        call search_exact_like
        search_exit:
            jmp choose
    input:                                             ;增加
        mov is_exist, 0
        lea dx, fun2                          
        call funstr                                   ;在输入层显示当前执行的操作为增加
        curse 7, 12                                    
        input_word 0, 20                              ;插入单词
        mov ax, is_exist
        cmp ax, 1
        jz input_exit                                 
        inc cnt                                       ;单词数量+1
        curse 13, 12
        input_word 20, 40                             ;插入注释
        curse 20, 12                                
        input_word 60, 20                             ;插入同义词
        curse 20, 51
        input_word 80, 20                             ;插入反义词
        call clear                                    ;清空结果
        input_exit:
            jmp choose
    modify:                                           ;修改单词
        lea dx, fun3                                   
        call funstr                                   ;在输入层显示当前执行的操作为修改
        curse 7, 12
        call find                                     ;调用查找函数，返回单词位置到pos，查找不到则输出提示信息，并置pos为-1
        mov cx, pos                                 
        cmp cx, -1                                    ;-1则代表查询不到，退出
        jz modify_exit                        
        mov now, cx
        curse 13, 12
        modify_word 20, 40                            ;修改解释，偏移地址为20，长度40
        curse 20, 12
        modify_word 60, 20                            ;修改同义词，偏移地址为60，长度20
        curse 20, 51
        modify_word 80, 20                            ;修改反义词，偏移地址为80，长度20
        call clear
        modify_exit:
            jmp choose 
    delete:                                           ;删除单词
        lea dx, fun4                                 
        call funstr                                   ;在输入层显示当前执行的操作为删除
        curse 7, 12                                   
        call find                                     ;调用查找函数，返回单词位置到pos，查找不到则输出提示信息，并置pos为-1
        mov cx, pos
        cmp cx, -1                                    ;-1则代表查询不到，退出
        jz delete_exit
        delete_word                                   ;根据pos位置删除单词
        dec cnt                                       ;单词数量-1
        call clear                                  
        delete_exit:
            jmp choose        
                 
    export:                                           ;导出数据至文件
        lea dx, file         
        mov al, 1                                     ;打开方式为写
        mov ah, 3DH                                   ;打开文件
        int 21h
        mov file_code, ax                             ;保存文件码
        mov ax, cnt                                   ;写入的字节数
        mov bl, 100
        mul bl
        mov cx, ax
        mov ah, 40H                                   ;写入文件
        mov bx, file_code                             ;将文件代号传送至bx
        lea dx, words                                 ;数据缓冲区地址 
        int 21h       
        mov bx, file_code                             ;将文件代号传送至bx
        mov ah, 3EH                                   ;关闭文件
        int 21h
         
    exit:        
        call exit_str                                 ;退出消息
        mov ax, 4c00h                                 ;结束程序
        int 21h  
    
;--------------------------------------------------函数定义--------------------------------------------------;
   
    init_str proc                                     ;显示界面字符串
        push ax
        push dx
        curse 2, 35
        mov ah, 09h                                   ;显示字典
        lea dx, str0                                
        int 21h
        curse 12, 4
        mov ah, 09h                                   ;显示注释
        lea dx, str2
        int 21h
        curse 18, 4
        mov ah, 09h                                   ;显示同义词
        lea dx, str3
        int 21h
        curse 18, 43
        mov ah, 09h                                   ;显示反义词
        lea dx, str4
        int 21h
        curse 7, 4     
        mov ah, 09h                                   ;显示选择消息
        lea dx, str1
        int 21h        
        pop dx
        pop ax
        ret
    init_str endp
    
    exit_str proc                                     ;结束页面
        push dx
        push ax
        scroll 0, 1, 1, 23, 78, 72h                   ;清屏
        curse 11, 28
        mov ah, 09h
        lea dx, str5
        int 21h
        scroll 1, 1, 1, 23, 78, 72h                   ;上卷一行
        curse 12, 38
        mov ah, 09h
        lea dx, str6
        int 21h
        mov ah, 0                                     ;等待输入
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
        scroll 4, 5, 1, 9, 78, 71h                    ;输入层清空
        scroll 3, 13, 1, 15，78, 72h                  ;解释层清空
        scroll 4, 19, 1, 23，38, 72h                  ;同义词层清空
        scroll 4, 19, 40, 23, 78, 72h                 ;反义词层清空
        curse 7, 23
        mov ah, 09h                                   ;输入层显示成功消息
        lea dx, success_msg
        int 21h
        mov ah, 0                                     ;等待输入
        int 16h                                      
        scroll 4, 5, 1, 9, 78, 71h                    ;输入层清空
        curse 7, 4     
        mov ah, 09h
        lea dx, str1                                  ;输入层显示选择消息
        int 21h
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    clear endp
    
    funstr proc                                       ;输出当前功能提示字符
        push ax
        push bx
        push cx
        push dx
        scroll 23, 5, 1, 6, 78, 71h                   ;输入层提示字体蓝色
        scroll 23, 7, 1, 9, 78, 72h                   ;输入层
        curse 6, 4                                 
        mov ah, 09h
        pop dx        
        int 21h
        pop cx
        pop bx
        pop ax
        ret
    funstr endp  
    
    find proc                                         ;精确寻找单词
        push dx
        push cx
        push bx                                      
        push ax
        mov ah, 0ah                                   ;输入
        lea dx, word
        int 21h
        call warning
        cld                                       
        mov cx, cnt                                   ;已存储的单词数量
        jcxz notequal_find                            ;cx为0则肯定找不到单词
        for1_find:                                 
            push cx                                   ;存储已经访问到第几个单词
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100
            mul bl                                    ;记录第cx-1个单词的首地址 
            mov di, ax
            dec di                                    ;后面统一加1,所以这里提前减1
            xor cx, cx                                       
            lea si, word[2]                           ;单词的第一个字母地址
            mov cl, [si-1]                            ;新增单词的长度          
            for2_find:
                inc di
                lodsb
                cmp al, words[di]
                jne outfor_find                       ;当前单词出现字母不相等
                loop for2_find                        ;字母相等继续往后判断
                inc di                                ;word部分判断完，全部相同则运行到此处
                cmp words[di], ' '                    ;判断words部分是否结束
                jnz outfor_find                       ;没有结束则继续判断
                pop cx                                ;结束则说明找到匹配单词
                mov pos, cx
                jmp find_exit                         
                outfor_find:                          ;出现不相等则到外循环判断下一个单词
                    pop cx                            
                    loop for1_find
            notequal_find:                            ;运行到此处说明匹配不到单词
                mov pos, -1
                scroll 4, 5, 1, 9, 78, 71h            ;输入层               
                curse 7, 15
                mov ah, 09h
                lea dx, not_find_msg
                int 21h
                mov ah, 0                             ;等待输入
                int 16h       
                scroll 4, 5, 1, 9, 78, 71h            ;输入层
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
        mov like_cnt, 0                               ;模糊查询结果数置为0
        mov ah, 0ah                                   ;输入
        lea dx, word                                  
        int 21h
        call warning                                  ;调用提示消息
        cld                                       
        mov cx, cnt                                   ;已存储的单词数量
        jcxz notequal_search                          ;cx为0则肯定找不到单词
        for1_search:                                 
            push cx                                   ;存储已经访问到第几个单词
            mov ax, cx                            
            dec ax
            xor bx, bx
            mov bl, 100
            mul bl                                    ;记录第cx-1个单词的首地址 
            mov di, ax
            dec di                                    ;后面统一加1,所以这里提前减1
            xor cx, cx                                       
            lea si, word[2]                           ;单词的第一个字母地址
            mov cl, [si-1]                            ;新增单词的长度          
            for2_search:
                inc di
                lodsb
                cmp al, words[di]
                jne outfor_search                     ;当前单词出现字母不相等
                loop for2_search                      ;字母相等继续往后判断
                inc di                                ;word部分判断完，全部相同则运行到此处
                cmp words[di], ' '                    ;判断words部分是否结束
                jz search_exact                       ;结束则精确输出结果
                pop cx
                push cx
                mov pos, cx
                inc like_cnt                          ;增加模糊查询的结果数量后继续下一个单词的查询   
                outfor_search:                        ;出现不相等则到外循环判断下一个单词
                    pop cx                            
                    loop for1_search
                cmp like_cnt, 0
                jnz search_like                       ;like_cnt不为0则输出模糊查询结果，否则输出查找不到单词
            notequal_search:                          ;运行到此处说明匹配不到单词
                scroll 4, 5, 1, 9, 78, 71h            ;输入层               
                curse 7, 15                          
                mov ah, 09h
                lea dx, not_find_msg
                int 21h
                mov ah, 0                             ;等待输入
                int 16h       
                scroll 4, 5, 1, 9, 78, 71h            ;输入层
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
                mul bl                                ;计算出变址，即应该在哪开始输出
                lea bx, words
                add ax, bx                            ;单词所在位置
                add ax, 20                            ;从words[20]开始
                mov si, ax                                               
                lea di, word
                mov cx, 40
                for_explain:                          ;输出解释
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
                for_synonym:                          ;输出同义词
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
                for_antonym:                          ;输出反义词
                    lodsb
                    stosb
                    loop for_antonym
                curse 20, 51  
                mov word[19], '$'
                mov ah, 09h
                lea dx, word
                int 21h
                mov ah, 0                             ;等待输入
                int 16h                             
                call clear
                jmp search_exact_like_exit
            search_like:
                scroll 23, 11, 1, 13，78, 71h         ;更改ui
                scroll 23, 14, 1, 23，78, 72h         ;更改ui
                curse 13, 7
                mov ah, 09h
                lea dx, search_like_msg
                int 21h
                mov cx, like_cnt
                search_like_for1:
                    push cx
                    mov ax, pos
                    inc pos                           ;每运行一次pos跳到下一个单词
                    dec ax
                    xor bx, bx
                    mov bl, 100                            
                    mul bl                            ;计算出变址，即应该在哪开始输出
                    lea bx, words
                    add ax, bx                        ;单词所在位置
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
                    scroll 1, 15, 1, 21，78, 72h
                    pop cx
                    dec cx
                    cmp cx, 0
                    jnz search_like_for1
                    mov ah, 0                         ;等待输入
                    int 16h                     
                    scroll 4, 5, 1, 9, 78, 71h        ;清除输入层
                    scroll 13, 11, 1, 23, 78, 30h     ;清除近似查找结果 
                    ;构造解释层和同义、反义层
                    scroll 23, 11, 1, 12，78, 71h     ;解释层提示字体蓝色
                    scroll 23, 13, 1, 15，78, 72h     ;解释层
                    scroll 23, 17, 1, 18，38, 71h     ;最底层提示字体蓝色
                    scroll 23, 17, 40, 18，78, 71h    ;最底层提示字体蓝色
                    scroll 23, 19, 1, 23，38, 72h     ;同义词层
                    scroll 23, 19, 40, 23, 78, 72h    ;反义词层
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
                    call init_str                     ;初始化界面
        search_exact_like_exit:    
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    search_exact_like endp 
    
    warning proc                                      ;等待提示
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