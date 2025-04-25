package lab1

main(): Int64 {
    // 创建 NFA 图，表示基本的 NFA，生成 'a' 和 'b' 字符的图
    var nfa_a: Graph = generateBasicNFA(CHAR, UInt32(r'a'))
    var nfa_b: Graph = generateBasicNFA(CHAR, UInt32(r'b'))
    var nfa_i: Graph = generateBasicNFA(CHAR, UInt32(r'i'))
    var nfa_f: Graph = generateBasicNFA(CHAR, UInt32(r'f'))
    var nfa_t: Graph = generateBasicNFA(CHAR, UInt32(r't'))
    var nfa_h: Graph = generateBasicNFA(CHAR, UInt32(r'h'))
    var nfa_e: Graph = generateBasicNFA(CHAR, UInt32(r'e'))
    var nfa_n: Graph = generateBasicNFA(CHAR, UInt32(r'n'))
    var nfa_l: Graph = generateBasicNFA(CHAR, UInt32(r'l'))
    var nfa_s: Graph = generateBasicNFA(CHAR, UInt32(r's'))
    var nfa_d: Graph = generateBasicNFA(CHAR, UInt32(r'd'))
    var nfa_r: Graph = generateBasicNFA(CHAR, UInt32(r'r'))
    var nfa_p: Graph = generateBasicNFA(CHAR, UInt32(r'p'))
    var nfa_u: Graph = generateBasicNFA(CHAR, UInt32(r'u'))
    var nfa_w: Graph = generateBasicNFA(CHAR, UInt32(r'w'))


    // 使用 NFA 并运算生成 a|b 的图
    var nfa_aorb: Graph = unionNFA(nfa_a, nfa_b)

    // 对 a|b 执行闭包操作
    var nfa_star: Graph = closureNFA(nfa_aorb)

    // 构造 abb
    var nfa_a2: Graph = generateBasicNFA(CHAR, UInt32(r'a'))
    var nfa_b2: Graph = generateBasicNFA(CHAR, UInt32(r'b'))
    var nfa_b3: Graph = generateBasicNFA(CHAR, UInt32(r'b'))

    // 使用 NFA 连接运算构造 ab 和 abb
    var nfa_ab: Graph = productNFA(nfa_a2, nfa_b2)
    var nfa_abb: Graph = productNFA(nfa_ab, nfa_b3)

    // 将 (a|b)* 与 abb 连接
    var nfa_final: Graph = productNFA(nfa_star, nfa_abb)

    println("=== NFA for (a|b)*abb ===")
    printGraph(nfa_final)

    // 转换为 DFA
    var dfa: Graph = NFA_to_DFA(nfa_final)

    println("=== DFA for (a|b)*abb ===")
    printGraph(dfa)

    println()
    println()
    println()


    // // 1. 生成基本 NFA，匹配字符 'a' 
    // let nfa_a = generateBasicNFA(CHAR, UInt32(r'a'));
    // println("Basic NFA for 'a':")
    // printGraph(nfa_a)

    // // 2. 生成基本 NFA，匹配字符 'b'
    // let nfa_b = generateBasicNFA(CHAR, UInt32(r'b'));
    // println("Basic NFA for 'b':")
    // printGraph(nfa_b);

    // // 3. 并运算 (a|b)
    // let union_nfa = unionNFA(nfa_a, nfa_b);
    // println("Union NFA for (a|b):")
    // printGraph(union_nfa);

    // // 4. 连接运算 (ab)
    // let product_nfa = productNFA(nfa_a, nfa_b);
    // // let product_nfa1 = productNFA(product_nfa, nfa_a)
    // println("Product NFA for (ab):")
    // printGraph(product_nfa);

    // // 5. 正闭包运算 (a+)
    // let plus_nfa = plusClosure(nfa_a);
    // println("Plus Closure NFA for (a+):")
    // printGraph(plus_nfa);

    // // 6. 闭包运算 (a*)
    // let closure_nfa = closureNFA(nfa_a);
    // println("Closure NFA for (a*):")
    // printGraph(closure_nfa);

    // // 7. 0或1 运算 (a?)
    // let zeroOrOne_nfa = zeroOrOneNFA(nfa_a);
    // println("ZeroOrOne NFA for (a?):")
    // printGraph(zeroOrOne_nfa);


    println()
    println()
    println()


    // 1. 创建 a~z 的字符范围
    let cs1 = range(r'a', r'z')
    println("Created range a-z:")
    printCharSet(cs1)

    let cs2 = range(r'A', r'Z')
    println("Created range A-Z:")
    printCharSet(cs2)

    // // 2. 两个字符 A 和 Z 的并运算
    // let cs2 = unionChars(r'A', r'Z')
    // println("\nCreated union of characters A and Z:")
    // printCharSet(cs2)

    // 3. 将字符 '0' 加入 a~z 的字符集中
    let cs3 = unionCharSetWithChar(cs1, r'_')
    println("\nUnion of range a-z with character A:")
    printCharSet(cs3)

    // 4. 合并 a~z 和 {A, Z} 两个字符集
    let letter = unionCharSets(cs2, cs3)
    println("\nUnion of range a-z and union of A and Z:")
    printCharSet(letter)

    let digit = range(r'0', r'9')

    // // 5. 从 a~z 的字符集中去掉字符 'm'
    // let cs5 = difference(cs1, r'm')
    // println("\nDifference of range a-z removing 'm':")
    // printCharSet(cs5)

    // 打印全局字符集表
    printTable()
    println("\n\n\n\n")



    // 标识符的正则表达式
    var nfa_1: Graph = generateBasicNFA(CHARSET, digit) // digit 数字的正则表达式
    var nfa_2: Graph = generateBasicNFA(CHARSET, letter) // letter
    var nfa_3: Graph = unionNFA(nfa_1, nfa_2) // (letter|digit)
    var nfa_4: Graph = closureNFA(nfa_3) // (letter|digit)*
    var id: Graph = productNFA(nfa_2, nfa_4) // letter(letter|digit)*
    setCategory(id, ID)
    // printGraph(id)

    // 关键字的正则表达式
    var int: Graph = productNFA(productNFA(nfa_i, nfa_n), nfa_t)
    setCategory(int, KEYWORD)
    var then: Graph = productNFA(productNFA(productNFA(nfa_t, nfa_h), nfa_e), nfa_n)
    setCategory(then, KEYWORD)
    var else_: Graph = productNFA(productNFA(productNFA(nfa_e, nfa_l), nfa_s), nfa_e)
    setCategory(else_, KEYWORD)
    var read: Graph = productNFA(productNFA(productNFA(nfa_r, nfa_e), nfa_a), nfa_d)
    setCategory(read, KEYWORD)
    var write: Graph = productNFA(productNFA(productNFA(productNFA(nfa_w, nfa_r), nfa_i), nfa_t), nfa_e)
    setCategory(read, KEYWORD)
    var keyword: Graph = unionNFA(unionNFA(read, write), else_)

    // 运算符的正则表达式
    var nfa_9: Graph = generateBasicNFA(CHAR, UInt32(r'+'))
    var nfa_10: Graph = generateBasicNFA(CHAR, UInt32(r'-'))
    var nfa_11: Graph = generateBasicNFA(CHAR, UInt32(r'*'))
    var nfa_12: Graph = generateBasicNFA(CHAR, UInt32(r'/'))    
    var nfa_13: Graph = generateBasicNFA(CHAR, UInt32(r'='))
    var nfa_14: Graph = generateBasicNFA(CHAR, UInt32(r'<'))
    var nfa_15: Graph = generateBasicNFA(CHAR, UInt32(r'>'))
    var calc: Graph = unionNFA(unionNFA(unionNFA(unionNFA(unionNFA(unionNFA(nfa_9, nfa_10), nfa_11), nfa_12), nfa_13), nfa_14), nfa_15)
    setCategory(calc, OPERATORS)


    // 赋值运算符的正则表达式
    var nfa_6: Graph = generateBasicNFA(CHAR, UInt32(r':'))
    var nfa_7: Graph = generateBasicNFA(CHAR, UInt32(r'='))
    var nfa_8: Graph = productNFA(nfa_6, nfa_7)
    setCategory(nfa_8, ASSIGNMENT)

    // 数字的正则表达式
    var number: Graph = plusClosure(nfa_1)
    setCategory(number, INTERGER_CONST)

    // 空白符的正则表达式
    var space: Graph = generateBasicNFA(CHAR, UInt32(r' '))
    var spaces: Graph = plusClosure(space)
    setCategory(spaces, WHITESPACE)

    // 分隔符的正则表达式
    var Separators: Graph = generateBasicNFA(CHAR, UInt32(r';'))
    setCategory(Separators, SEPARATORS)

    var dfa1: Graph = NFA_to_DFA(id) // 标识符的DFA
    var dfa2: Graph = NFA_to_DFA(nfa_1) // 整数的DFA

    var nfa_lexeme: Graph = unionNFA(unionNFA(unionNFA(unionNFA(unionNFA(unionNFA(keyword, calc), nfa_8), number), id), spaces), Separators)
    var dfa_lexeme: Graph = NFA_to_DFA(nfa_lexeme)

    printGraph(dfa_lexeme)

    var tokens = tokenize(dfa_lexeme, "read x;\n y:=x*2;\n write y;")
    // var tokens = tokenize(dfa_lexeme, "int1 int ")
    for (i in tokens) {
        println("${i[0]}  ${i[1]}")
    }

    return 0
}