package lab2
import std.collection.*

/**
 *  实现FIRST/FOLLOW集合计算
 *  包含 get_All_NTS_FIRST() 和 get_All_NTS_FOLLOW() 核心算法
 */

// 求解单个产生式的FIRST函数
public func get_Production_FIRST(production:Production) {
    var nullStand:Bool = true;
    var i:Int64 = 0;

    // 处理每个文法符号
    while(nullStand && i<production.pBodySymbolTable.size) {
        var currGrammarSymbol:GrammarSymbol = production.pBodySymbolTable[i];
        // 如果是终结符
        if(currGrammarSymbol is TerminalSymbol) {
            nullStand = false;
            // 遇到终结符时停止继续推导
            var insert_Symbol:TerminalSymbol = currGrammarSymbol as TerminalSymbol ?? none_TerminalSymbol;
            if(insert_Symbol != none_TerminalSymbol) {
                // 加入FIRST集合
                production.pFirstSet.put(insert_Symbol);
            }
        } 
        // 如果是非终结符
        else {
            var insert_Symbol:NonTerminalSymbol = currGrammarSymbol as NonTerminalSymbol ?? none_NonTerminalSymbol;
            if(insert_Symbol != none_NonTerminalSymbol) {
                // 合并非终结符的FIRST集合
                production.pFirstSet.putAll(insert_Symbol.pFirstSet);
                // 暂时移除空符
                production.pFirstSet.remove(ts_null);
                if(!insert_Symbol.pFirstSet.contains(ts_null)) {
                    // 当非终结符FIRST不含空时停止推导
                    nullStand = false;
                }
            }
        }
    }
    if(nullStand && i == production.pBodySymbolTable.size) {
        // 所有符号可推导为空时加入空符
        production.pFirstSet.put(ts_null);
    }
}

// 求解所有产生式的FIRST
public func get_All_Production_FIRST(){
    for(production in all_Production_Set) {
        get_Production_FIRST(production);
    }
}

// 求出所有的非终结符的FIRST
public func get_All_NTS_FIRST(){
    // 记录每个NTS的依赖项
    var task_table:HashMap<NonTerminalSymbol, HashSet<NonTerminalSymbol>> = HashMap<NonTerminalSymbol, HashSet<NonTerminalSymbol>>();
    for(nfs in all_NonTerminalSymbol_Set) {
        task_table.put(nfs,HashSet<NonTerminalSymbol>());
    }
    // 已经得到其FIRST函数的nts
    var accomplish_set:HashSet<NonTerminalSymbol> = HashSet<NonTerminalSymbol>();
    // 多轮迭代处理，逐步解决依赖链
    while(accomplish_set.size != all_NonTerminalSymbol_Set.size) {
        for(nts in all_NonTerminalSymbol_Set) {
            // 是否独立(无未计算出的FIRST依赖)
            var independent = true;
            for(production in nts.pProductionTable) {
                // 找到产生式第一个grammar
                var grammarSymbol:GrammarSymbol = production.pBodySymbolTable[0];
                if(grammarSymbol is NonTerminalSymbol) {
                    // 处理首符号为非终结符的情况
                    var insert_nts:NonTerminalSymbol = grammarSymbol as NonTerminalSymbol ?? none_NonTerminalSymbol;
                    if(insert_nts != none_NonTerminalSymbol) {
                        if(accomplish_set.contains(insert_nts)) {
                            // 已完成的NTS直接合并其FIRST集合
                            nts.pFirstSet.putAll(insert_nts.pFirstSet);
                            task_table[nts].remove(insert_nts);
                        } else {
                            // 避免非终结符依赖自身形成死循环
                            if(insert_nts != nts) {
                                // 未完成的NTS记录到task_table
                                task_table[nts].put(insert_nts);
                                independent = false;
                            }
                        }
                    }
                } else {
                    // 处理首符号为终结符的情况
                    var insert_ts:TerminalSymbol = grammarSymbol as TerminalSymbol ?? none_TerminalSymbol;
                    if(insert_ts != none_TerminalSymbol) {
                        nts.pFirstSet.put(insert_ts);
                    }
                }
            }
            if(independent) {
                accomplish_set.put(nts);
            }
        }
    }
}

// 求解FOLLOW函数中需要的辅助FIRST（包含终结符的FIRST即为它本身）
public func FIRST(grammerSymbol:GrammarSymbol):HashSet<TerminalSymbol> {
    if(grammerSymbol is NonTerminalSymbol) {
        // 非终结符直接返回非终结符的FIRST集合
        var temp_nts:NonTerminalSymbol = grammerSymbol as NonTerminalSymbol ?? none_NonTerminalSymbol;
        return temp_nts.pFirstSet;
    } else {
        // 终结符返回只包含自身的集合
        var temp_ts:TerminalSymbol = grammerSymbol as TerminalSymbol ?? none_TerminalSymbol;
        var res_set:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
        res_set.put(temp_ts);
        return res_set;
    }
}

// 求出所有非终结符的FOLLOW函数
public func get_All_NTS_FOLLOW(){
    // 初始化FOLLOW集合和依赖关系
    for(nts in all_NonTerminalSymbol_Set) {
        // 遍历所有非终结符
        for(production in nts.pProductionTable) {
            // 遍历该非终结符的所有产生式
            var i:Int64 = production.pBodySymbolTable.size - 1;
            var grammerSymbol:GrammarSymbol = production.pBodySymbolTable[i];
            // 处理产生式最右端的非终结符
            if(grammerSymbol is NonTerminalSymbol) {
                var temp_nts = grammerSymbol as NonTerminalSymbol ?? none_NonTerminalSymbol;
                if(temp_nts != none_NonTerminalSymbol) {
                    // 添加FOLLOW集合依赖关系（不能依赖自身）
                    if(temp_nts != nts){
                        temp_nts.pDependentSetInFollow.put(nts);
                    }
                }
            }

            // 反向扫描产生式体
            var nullStand:Bool = true;
            // 标记后续符号是否都能推导为空
            var j:Int64 = production.pBodySymbolTable.size-1;
            // 当前处理区间的右边界
            i = i-1;
            while(i>=0) {
                // 从右向左扫描产生式体
                var curr_gs:GrammarSymbol = production.pBodySymbolTable[i];
                if(curr_gs is NonTerminalSymbol) {
                    var temp_nts = curr_gs as NonTerminalSymbol ?? none_NonTerminalSymbol;
                    if(temp_nts != none_NonTerminalSymbol) {
                        // 处理符号右侧的符号链（i+1到j区间）
                        var k:Int64 = i+1;
                        while(k<=j) {
                            var insert_k_gs:GrammarSymbol = production.pBodySymbolTable[k];
                            // 合并右侧符号的FIRST集合（去除空符）
                            temp_nts.pFollowSet.putAll(FIRST(insert_k_gs));
                            temp_nts.pFollowSet.remove(ts_null);
                            k++;
                        }
                        // 更新处理区间边界
                        if(!temp_nts.pFirstSet.contains(ts_null)) {
                            // 右侧符号无法推导为空时缩小处理区间
                            j = i;
                        }
                        // 检查下一个符号是否包含空符
                        if(nullStand && !FIRST(production.pBodySymbolTable[i+1]).contains(ts_null)) {
                            // 发现不可推导为空的符号
                            nullStand = false;
                        }
                        // 添加FOLLOW集合依赖（当前符号可推导为空且非自身依赖）
                        if(nullStand && temp_nts != nts) {
                            temp_nts.pDependentSetInFollow.put(nts);
                        }
                    }
                } else {
                    // 遇到终结符的情况
                    j = i;
                    // 重置处理区间右边界
                    if(nullStand) {
                        nullStand = false;
                        // 终结符不可推导为空
                    }
                }
                i--;  // 继续向左处理
            }
        }
    }

    // 依赖关系解析
    var curr_dependence_edge_num:Int64 = 0;  // 当前依赖边数量
    var before_dependence_edge_num:Int64 = 0;  // 前次依赖边数量
    var dependence_map:HashMap<NonTerminalSymbol, HashSet<NonTerminalSymbol>> = HashMap<NonTerminalSymbol, HashSet<NonTerminalSymbol>>();
    
    // 初始化依赖图
    for(nts in all_NonTerminalSymbol_Set) {
        dependence_map.put(nts,HashSet<NonTerminalSymbol>());
        dependence_map[nts].putAll(nts.pDependentSetInFollow);
        // 添加依赖边的数量
        curr_dependence_edge_num += nts.pDependentSetInFollow.size;
        before_dependence_edge_num +=nts.pDependentSetInFollow.size;
    }

    // 拓扑排序处理依赖
    var accomplishment:HashSet<NonTerminalSymbol> = HashSet<NonTerminalSymbol>();  // 已完成计算的NTS集合
    for(nts in all_NonTerminalSymbol_Set) {
        if(nts.pDependentSetInFollow.isEmpty()) {
            accomplishment.put(nts);
        }
    }
    // 根据依赖FOLLOW来求解所有的非终结符的FOLLOW
    while(accomplishment.size != all_NonTerminalSymbol_Set.size) {
        // 处理正常依赖关系
        for(nts in all_NonTerminalSymbol_Set) {
            for(dependence in dependence_map[nts]) {
                if(accomplishment.contains(dependence)) {
                    nts.pFollowSet.putAll(dependence.pFollowSet);  // 合并已完成的FOLLOW集合
                    curr_dependence_edge_num --;
                }
            }
            dependence_map[nts].removeAll(accomplishment);
            if(dependence_map[nts].isEmpty()) {
                accomplishment.put(nts);  // 标记为已完成
            }
        }
        
        // 处理循环依赖（当依赖边数量未减少时）
        if(curr_dependence_edge_num == before_dependence_edge_num) {
            // 选择未完成的NTS进行强制处理
            var deal_nts:NonTerminalSymbol = none_NonTerminalSymbol;
            for(nts in all_NonTerminalSymbol_Set) {
                if(!accomplishment.contains(nts)) {
                    deal_nts = nts;
                }
            }

            if(deal_nts != none_NonTerminalSymbol) {
                // 广度优先遍历所有相关NTS
                var has_show_nts:HashSet<NonTerminalSymbol> = HashSet<NonTerminalSymbol>();
                var task_queue:ArrayList<NonTerminalSymbol> = ArrayList<NonTerminalSymbol>();
                for(dependence in dependence_map[deal_nts]) {
                    if(!has_show_nts.contains(dependence)) {
                        task_queue.append(dependence);
                        has_show_nts.put(dependence);
                    }
                }
                while(!task_queue.isEmpty()) {
                    // 取出队首
                    var headNts:NonTerminalSymbol = task_queue[0];
                    task_queue.remove(0);
                    for(dependence in dependence_map[headNts]) {
                        if(!has_show_nts.contains(dependence)) {
                            task_queue.append(dependence);
                            has_show_nts.put(dependence);
                        }
                    }
                }
                // 合并所有相关FOLLOW集合
                for(cNTS in has_show_nts) {
                    deal_nts.pFollowSet.putAll(cNTS.pFollowSet);
                }
                // 强制标记为已完成
                accomplishment.put(deal_nts);
                curr_dependence_edge_num -= dependence_map[deal_nts].size;
                before_dependence_edge_num = curr_dependence_edge_num;
                dependence_map[deal_nts].clear();
            }
        } else {
            before_dependence_edge_num = curr_dependence_edge_num;
        }
    }
}



// 展示所有非终结符的FIRST函数
public func show_All_NTS_FIRST(){
    for(nfs in all_NonTerminalSymbol_Set) {
        print("name: ${nfs.name} FIRST: {");
        for(ts in nfs.pFirstSet) {
            print(" ${ts.name} ");
        }
        println("}");
    }
}

// 展示所有产生式的FIRST
public func show_All_Production_FIRST(){
    for(production in all_Production_Set) {
        print("PRODUCTION: ");
        for(grammar in production.pBodySymbolTable) {
            print("${grammar.name} ");
        }
        println();
        print("FIRST: ");
        for(ts in production.pFirstSet) {
            print("${ts.name} ");
        }
        println();
    }
}

// 展示所有非终结符以及其产生式集合
public func show_All_nts_production(){
    for(nts in all_NonTerminalSymbol_Set) {
        println("name: ${nts.name} ");
        for(p in nts.pProductionTable) {
            print("   ");
            for(s in p.pBodySymbolTable) {
                print("${s.name} ")
            }
            println();
        }
    }
}

// 展示所有非终结符的FOLLOW函数
public func show_All_NTS_FOLLOW() {
    for(nts in all_NonTerminalSymbol_Set) {
        print("name: ${nts.name} FOLLOW: {");
        for(follow_symbol in nts.pFollowSet) {
            print(" ${follow_symbol.name} ");
        }
        println("}");
    }
}



// 创建测试样例 文法3.5
public func test1(){

    // 创建非终结符E
    var name_E:String = "E";
    var pProductionTable_E = ArrayList<Production>();
    var numOfProduction_E = 1;
    var pFirstSet_E = HashSet<TerminalSymbol>();
    var pFollowSet_E = HashSet<TerminalSymbol>();
    var pDependentSetInFollow_E = HashSet<NonTerminalSymbol>();
    var nts_E:NonTerminalSymbol = NonTerminalSymbol(name_E,non_s,pProductionTable_E,numOfProduction_E,pFirstSet_E,pFollowSet_E,pDependentSetInFollow_E);
    all_NonTerminalSymbol_Set.append(nts_E);

    // 创建非终结符E'
    var name_E1:String = "E'";
    var pProductionTable_E1 = ArrayList<Production>();
    var numOfProduction_E1 = 1;
    var pFirstSet_E1 = HashSet<TerminalSymbol>();
    var pFollowSet_E1 = HashSet<TerminalSymbol>();
    var pDependentSetInFollow_E1 = HashSet<NonTerminalSymbol>();
    var nts_E1:NonTerminalSymbol = NonTerminalSymbol(name_E1,non_s,pProductionTable_E1,numOfProduction_E1,pFirstSet_E1,pFollowSet_E1,pDependentSetInFollow_E1);
    all_NonTerminalSymbol_Set.append(nts_E1);

    // 创建非终结符T
    var name_T:String = "T";
    var pProductionTable_T = ArrayList<Production>();
    var numOfProduction_T = 1;
    var pFirstSet_T = HashSet<TerminalSymbol>();
    var pFollowSet_T = HashSet<TerminalSymbol>();
    var pDependentSetInFollow_T = HashSet<NonTerminalSymbol>();
    var nts_T:NonTerminalSymbol = NonTerminalSymbol(name_T,non_s,pProductionTable_T,numOfProduction_T,pFirstSet_T,pFollowSet_T,pDependentSetInFollow_T);
    all_NonTerminalSymbol_Set.append(nts_T);

    // 创建非终结符T'
    var name_T1:String = "T'";
    var pProductionTable_T1 = ArrayList<Production>();
    var numOfProduction_T1 = 1;
    var pFirstSet_T1 = HashSet<TerminalSymbol>();
    var pFollowSet_T1 = HashSet<TerminalSymbol>();
    var pDependentSetInFollow_T1 = HashSet<NonTerminalSymbol>();
    var nts_T1:NonTerminalSymbol = NonTerminalSymbol(name_T1,non_s,pProductionTable_T1,numOfProduction_T1,pFirstSet_T1,pFollowSet_T1,pDependentSetInFollow_T1);
    all_NonTerminalSymbol_Set.append(nts_T1);

    // 创建非终结符F
    var name_F:String = "F";
    var pProductionTable_F = ArrayList<Production>();
    var numOfProduction_F = 1;
    var pFirstSet_F = HashSet<TerminalSymbol>();
    var pFollowSet_F = HashSet<TerminalSymbol>();
    var pDependentSetInFollow_F = HashSet<NonTerminalSymbol>();
    var nts_F:NonTerminalSymbol = NonTerminalSymbol(name_F,non_s,pProductionTable_F,numOfProduction_F,pFirstSet_F,pFollowSet_F,pDependentSetInFollow_F);
    all_NonTerminalSymbol_Set.append(nts_F);

    // 创建终结符+
    var name_plus:String = "+";
    var lexeme_plus:String = "OPERATOR+";
    var ts_plus = TerminalSymbol(name_plus,ter_s,lexeme_plus);

    // 创建终结符(
    var name_left_bracket:String ="(";
    var lexeme_left_bracket:String = "LEFT BRACKET";
    var ts_left_bracket = TerminalSymbol(name_left_bracket,ter_s,lexeme_left_bracket);

    // 创建终结符)
    var name_right_bracket:String =")";
    var lexeme_right_bracket:String = "RIGHT BRACKET";
    var ts_right_bracket = TerminalSymbol(name_right_bracket,ter_s,lexeme_right_bracket);

    // 创建终结符*
    var name_multiple:String ="*";
    var lexeme_multiple:String = "OPERATOR*";
    var ts_multiple = TerminalSymbol(name_multiple,ter_s,lexeme_multiple);

    // 创建终结符id
    var name_id:String = "id";
    var lexeme_id:String = "ID";
    var ts_id = TerminalSymbol(name_id,ter_s,lexeme_id);

    // 创建终结符$
    var name_shut:String = "$";
    var lexeme_shut:String = "$";
    var ts_shut = TerminalSymbol(name_shut,ter_s,lexeme_shut);
    // 把结束符$是开始符的FOLLOW天然已知条件添加进去
    nts_E.pFollowSet.put(ts_shut);

    // 创建产生式 E->T E'
    var production_1_id:Int64 = 1;
    var production_1_size:Int64 = 2;
    var production_1_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_1_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_1:Production = Production(production_1_id,production_1_size,production_1_sTable,production_1_fSet);
    production_1.pBodySymbolTable.append(nts_T);
    production_1.pBodySymbolTable.append(nts_E1);
    // 将其添加进E的产生式中
    nts_E.pProductionTable.append(production_1);
    nts_E.numOfProduction = 1;
    all_Production_Set.append(production_1);
    relativeId.append(0);

    // 创建产生式 E'->+ T E'
    var production_2_id:Int64 = 2;
    var production_2_size:Int64 = 3;
    var production_2_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_2_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_2:Production = Production(production_2_id,production_2_size,production_2_sTable,production_2_fSet);
    production_2.pBodySymbolTable.append(ts_plus);
    production_2.pBodySymbolTable.append(nts_T);
    production_2.pBodySymbolTable.append(nts_E1);
    // 将其添加进E'的产生式中
    nts_E1.pProductionTable.append(production_2);
    nts_E1.numOfProduction = 2;
    all_Production_Set.append(production_2);
    relativeId.append(1);
    
    // 创建产生式 E'-> null
    var production_3_id:Int64 = 3;
    var production_3_size:Int64 = 1;
    var production_3_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_3_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_3:Production = Production(production_3_id,production_3_size,production_3_sTable,production_3_fSet);
    production_3.pBodySymbolTable.append(ts_null);
    // 将其添加进E'的产生式中
    nts_E1.pProductionTable.append(production_3);
    nts_E1.numOfProduction = 2;
    all_Production_Set.append(production_3);
    relativeId.append(1);
    
    // 创建产生式 T->F T'
    var production_4_id:Int64 = 4;
    var production_4_size:Int64 = 2;
    var production_4_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_4_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_4:Production = Production(production_4_id,production_4_size,production_4_sTable,production_4_fSet);
    production_4.pBodySymbolTable.append(nts_F);
    production_4.pBodySymbolTable.append(nts_T1);
    // 将其添加进T的产生式中
    nts_T.pProductionTable.append(production_4);
    nts_T.numOfProduction = 1;
    all_Production_Set.append(production_4);
    relativeId.append(2)
    
    // 创建产生式 T'->* F T'
    var production_5_id:Int64 = 5;
    var production_5_size:Int64 = 3;
    var production_5_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_5_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_5:Production = Production(production_5_id,production_5_size,production_5_sTable,production_5_fSet);
    production_5.pBodySymbolTable.append(ts_multiple);
    production_5.pBodySymbolTable.append(nts_F);
    production_5.pBodySymbolTable.append(nts_T1);
    // 将其添加进T'的产生式中
    nts_T1.pProductionTable.append(production_5);
    nts_T1.numOfProduction = 2;
    all_Production_Set.append(production_5);
    relativeId.append(3);
    
    // 创建产生式 T'->null
    var production_6_id:Int64 = 6;
    var production_6_size:Int64 = 1;
    var production_6_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_6_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_6:Production = Production(production_6_id,production_6_size,production_6_sTable,production_6_fSet);
    production_6.pBodySymbolTable.append(ts_null);
    // 将其添加进T'的产生式中
    nts_T1.pProductionTable.append(production_6);
    nts_T1.numOfProduction = 2;
    all_Production_Set.append(production_6);
    relativeId.append(3);
    
    // 创建产生式 F->( E )
    var production_7_id:Int64 = 7;
    var production_7_size:Int64 = 3;
    var production_7_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_7_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_7:Production = Production(production_7_id,production_7_size,production_7_sTable,production_7_fSet);
    production_7.pBodySymbolTable.append(ts_left_bracket);
    production_7.pBodySymbolTable.append(nts_E);
    production_7.pBodySymbolTable.append(ts_right_bracket);
    // 将其添加进T'的产生式中
    nts_F.pProductionTable.append(production_7);
    nts_F.numOfProduction = 2;
    all_Production_Set.append(production_7);
    relativeId.append(4);
    
    // 创建产生式 F->id
    var production_8_id:Int64 = 8;
    var production_8_size:Int64 = 1;
    var production_8_sTable:ArrayList<GrammarSymbol> = ArrayList<GrammarSymbol>();
    var production_8_fSet:HashSet<TerminalSymbol> = HashSet<TerminalSymbol>();
    var production_8:Production = Production(production_8_id,production_8_size,production_8_sTable,production_8_fSet);
    production_8.pBodySymbolTable.append(ts_id);
    // 将其添加进T'的产生式中
    nts_F.pProductionTable.append(production_8);
    nts_F.numOfProduction = 2;
    all_Production_Set.append(production_8);
    relativeId.append(4);
    
}