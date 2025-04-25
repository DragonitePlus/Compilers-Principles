package lab1

import std.collection.*
import std.sort.*


// 存储 DFA 状态的转换信息，待全部生成后再添加边
struct DFATransition {
    var from: Int64
    var symbol: UInt32
    var to: Int64
    init(from: Int64, symbol: UInt32, to: Int64) {
        this.from = from
        this.symbol = symbol
        this.to = to
    }
}

enum DriverType {
    | NULL
    | CHAR
    | CHARSET
}

enum StateType {
    | UNMATCH
    | MATCH
}

enum LexemeCategory {
    | INTERGER_CONST
    | FLOAT_CONST
    | STRING_CONST
    | ID
    | NONE
    | KEYWORD
    | OPERATORS
    | ASSIGNMENT
    | WHITESPACE
    | SEPARATORS
}

class Edge {
    var fromState: Int64
    var nextState: Int64
    var driverId: UInt32
    var etype: DriverType

    init(from: Int64, next: Int64, driver: UInt32, dt: DriverType) {
        this.fromState = from
        this.nextState = next
        this.driverId = driver
        this.etype = dt
    }
}

class State {
    var stateId: Int64
    var stype: StateType
    var category: LexemeCategory = NONE

    init(id: Int64, stype: StateType) {
        this.stateId = id
        this.stype = stype
    }
}

class Graph {
    var graphId: Int64
    var numOfStates: Int64
    var pEdgeTable: ArrayList<Edge>
    var pStateTable: ArrayList<State>

    init(id: Int64) {
        this.graphId = id
        this.numOfStates = 0
        this.pEdgeTable = ArrayList<Edge>()
        this.pStateTable = ArrayList<State>()
    }

    func addState(state: State) {
        this.pStateTable.append(state)
        this.numOfStates = this.numOfStates + 1
    }

    func addEdge(edge: Edge) {
        this.pEdgeTable.append(edge)
    }
}

// 全局计数器，生成唯一的状态 id 和图 id
var graphIdCounter: Int64 = 1

// 生成基本 NFA：创建两个状态（起始状态和接受状态），并在起始状态与接受状态之间添加一条指定条件的边
func generateBasicNFA(driverType: DriverType, driverId: UInt32): Graph {
    let g = Graph(graphIdCounter)
    graphIdCounter += 1
    let start = State(0, UNMATCH)
    let accept = State(1, MATCH)
    g.addState(start)
    g.addState(accept)
    // 从 start 到 accept 添加边（无额外出边的接受状态）
    g.addEdge(Edge(start.stateId, accept.stateId, driverId, driverType))
    return g
}

// 并运算：构造新的 NFA，使得新起始状态通过 ε 边分别指向两个 NFA 的起始状态，新两个 NFA 的接受状态通过 ε 边指向新接受状态
func unionNFA(pNFA1: Graph, pNFA2: Graph): Graph {
    var hasOutEdges1 = false
    var hasInEdges1 = false
    var hasOutEdges2 = false
    var hasInEdges2 = false
    var hasCategory1 = false
    var hasCategory2 = false        
    let g = Graph(graphIdCounter)
    graphIdCounter += 1


    // 检查 pNFA1 是否有出边
    for (e in pNFA1.pEdgeTable) {
        // 检查是否存在来自最后一个状态的出边（可能影响合并后的状态迁移）
        if (e.fromState == pNFA1.pStateTable[pNFA1.numOfStates - 1].stateId) {
            hasOutEdges1 = true
        }  
        // 检测是否存在指向初始状态的入边（可能形成循环依赖）
        if (e.nextState == pNFA1.pStateTable[0].stateId) {
            hasInEdges1 = true
        }
    }
    // 处理NFA1结束状态的词法类别
    match (pNFA1.pStateTable[pNFA1.numOfStates-1].category) {
        // 普通接受状态
        case NONE => hasCategory1 = false
        // 携带特殊词法标记（如关键字/运算符）
        case _ => hasCategory1 = true
    }
    // 处理NFA2结束状态的词法类别
    match (pNFA2.pStateTable[pNFA2.numOfStates-1].category) {
        // 普通接受状态
        case NONE => hasCategory2 = false
        // 携带特殊词法标记（如关键字/运算符）
        case _ => hasCategory2 = true
    }


    // 检查 pNFA2 是否有入边
    for (e in pNFA2.pEdgeTable) {
        if (e.fromState == pNFA2.pStateTable[pNFA2.numOfStates - 1].stateId) {
            hasOutEdges2 = true
        }  
        if (e.nextState == pNFA2.pStateTable[0].stateId) {
            hasInEdges2 = true
        }
    }

    // 处理pNFA1的结束状态（出边或特殊词法类别）
    if (hasOutEdges1 || hasCategory1) {
        // 原结束状态改为普通状态
        pNFA1.pStateTable[pNFA1.numOfStates-1].stype = UNMATCH
        // 新建接受状态
        pNFA1.addState(State(pNFA1.numOfStates, MATCH))
        // 添加ε边
        pNFA1.addEdge(Edge(pNFA1.numOfStates-2, pNFA1.numOfStates-1, 0, NULL))
    } 
    if (hasOutEdges2 || hasCategory2) {
        pNFA2.pStateTable[pNFA2.numOfStates-1].stype = UNMATCH
        pNFA2.addState(State(pNFA2.numOfStates, MATCH))
        pNFA2.addEdge(Edge(pNFA2.numOfStates-2, pNFA2.numOfStates-1, 0, NULL))
    }

    // 处理pNFA1的入边（循环依赖）
    if (hasInEdges1) {
        // 复制所有的状态和边（避免与新初始状态冲突）
        for (s in pNFA1.pStateTable) {
            s.stateId += 1
        }
        for (e in pNFA1.pEdgeTable) {
            e.fromState += 1
            e.nextState += 1
        }
        // 添加新初始状态和ε边
        pNFA1.addState(State(0, UNMATCH))
        pNFA1.addEdge(Edge(0, 1, 0, NULL))      
    } 
    if (hasInEdges2) {
        // 复制所有的状态和边 
        for (s in pNFA2.pStateTable) {
            s.stateId += 1
        }
        for (e in pNFA2.pEdgeTable) {
            e.fromState += 1
            e.nextState += 1
        }
        pNFA2.addState(State(0, UNMATCH))
        pNFA2.addEdge(Edge(0, 1, 0, NULL))    
    } 

    // 计算新NFA的总状态数
    let maxState = pNFA1.numOfStates + pNFA2.numOfStates - 3
    // 构造新的NFA的起始和接受状态 
    let start = State(0, UNMATCH)
    let accept = State(maxState, MATCH)
    g.addState(start)
    // 添加pNFA1的中间状态（排除首尾状态）
    for (i in 1..pNFA1.numOfStates-1) {
        var temp_state: State = State(i, UNMATCH)
        temp_state.category = pNFA1.pStateTable[i].category
        g.addState(temp_state)
    }
    // 添加pNFA2的中间状态（排除首尾状态）
    for (i in 1..pNFA2.numOfStates-1) {
        var temp_state: State = State(i+pNFA1.numOfStates-2, UNMATCH)
        temp_state.category = pNFA2.pStateTable[i].category
        g.addState(temp_state)
    }
    g.addState(accept)
    
    // 构造新的NFA的边
    for (e in pNFA1.pEdgeTable) {
        if (e.nextState != pNFA1.numOfStates - 1) {
            // 普通边直接移植
            g.addEdge(Edge(e.fromState, e.nextState, e.driverId, e.etype))
        } else {
            // 原结束状态边重定向到新接受状态
            g.addEdge(Edge(e.fromState, maxState, e.driverId, e.etype))
        }
    }
    for (e in pNFA2.pEdgeTable) {
        if (e.fromState != 0) {
            // 非初始状态的边进行ID偏移
            g.addEdge(Edge(e.fromState+pNFA1.numOfStates-2, e.nextState+pNFA1.numOfStates-2, e.driverId, e.etype))
        } else {
            // 原初始状态边连接到pNFA1的中间状态
            g.addEdge(Edge(0, pNFA1.numOfStates-1, e.driverId, e.etype))
        }
    }
    
    return g
}



// 连接运算：将 pNFA1 与 pNFA2 串联。将 pNFA1 的接受状态通过 ε 边指向 pNFA2 的起始状态，并将 pNFA1 的接受状态改为非接受状态
func productNFA(pNFA1: Graph, pNFA2: Graph): Graph {
    var hasOutEdges = false
    var hasInEdges = false

    // 检查 pNFA1 是否有出边
    for (e in pNFA1.pEdgeTable) {
        if (e.fromState == pNFA1.pStateTable[pNFA1.numOfStates - 1].stateId) {
            hasOutEdges = true
            break
        }
    }

    // 检查 pNFA2 是否有入边
    for (e in pNFA2.pEdgeTable) {
        if (e.nextState == pNFA2.pStateTable[0].stateId) {
            hasInEdges = true
            break
        }
    }
    if (hasOutEdges && hasInEdges) {
        let maxState = pNFA1.numOfStates + pNFA2.numOfStates - 1
        let g = Graph(graphIdCounter)
        graphIdCounter += 1

        // 构造新的NFA的状态 
        let start = State(0, UNMATCH)
        let accept = State(maxState, MATCH)
        g.addState(start)
        for (i in 1..(maxState)) {
            g.addState(State(i, UNMATCH))
        }
        g.addState(accept)
        
        // 构造新的NFA的边
        for (e in pNFA1.pEdgeTable) {
            g.addEdge(e)
        }
        g.addEdge(Edge(pNFA1.numOfStates - 1, pNFA1.numOfStates , 0, NULL));
        for (e in pNFA2.pEdgeTable) {
            g.addEdge(Edge(e.fromState + pNFA1.numOfStates, e.nextState + pNFA1.numOfStates, e.driverId, e.etype))
        }

        return g
    } else {
        let maxState = pNFA1.numOfStates + pNFA2.numOfStates - 2
        let g = Graph(graphIdCounter)
        graphIdCounter += 1
        
        // 构造新的NFA的状态 
        let start = State(0, UNMATCH)
        let accept = State(maxState, MATCH)
        g.addState(start)
        for (i in 1..(maxState)) {
            g.addState(State(i, UNMATCH))
        }
        g.addState(accept)
        
        // 构造新的NFA的边
        for (e in pNFA1.pEdgeTable) {
            g.addEdge(e)
        }
        for (e in pNFA2.pEdgeTable) {
            g.addEdge(Edge(e.fromState + pNFA1.numOfStates - 1, e.nextState + pNFA1.numOfStates - 1, e.driverId, e.etype))
        }

        return g
    }
}

// 正闭包运算：要求至少出现一次。构造新 NFA，使新起始状态 ε 边到原起始状态；原接受状态 ε 边既回到原起始状态也到达新接受状态，同时将原接受状态改为非接受状态
func plusClosure(pNFA: Graph): Graph {
    let maxState = pNFA.numOfStates - 1
    let g = Graph(graphIdCounter)
    graphIdCounter += 1
    
    // 复制所有的状态和边 
    for (s in pNFA.pStateTable) {
        g.addState(s)
    }
    for (e in pNFA.pEdgeTable) {
        g.addEdge(e)
    }
    // 添加一条空转换的边，头状态到尾状态之间     
    g.addEdge(Edge(maxState, 0, 0, NULL))
    return g
}

// 闭包运算（Kleene 闭包）：允许 0 次或多次出现。与正闭包相比，新起始状态额外有一条 ε 边直接到新接受状态
func closureNFA(pNFA: Graph): Graph {
    var hasOutEdges = false
    var hasInEdges = false
    let g = Graph(graphIdCounter)
    graphIdCounter += 1

    // 检查 pNFA 的结束状态 是否有出边
    for (e in pNFA.pEdgeTable) {
        if (e.fromState == pNFA.pStateTable[pNFA.numOfStates - 1].stateId) {
            hasOutEdges = true
            break
        }
    }

    // 检查 pNFA2 的初始状态 是否有入边
    for (e in pNFA.pEdgeTable) {
        if (e.nextState == pNFA.pStateTable[0].stateId) {
            hasInEdges = true
            break
        }
    }
    //原NFA没有入边和出边
    if (!hasInEdges && !hasOutEdges) {
        let maxState = pNFA.numOfStates - 1
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(s)
        }
        for (e in pNFA.pEdgeTable) {
            g.addEdge(e)
        }
        // 添加两条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, maxState, 0, NULL))
        g.addEdge(Edge(maxState, 0, 0, NULL))
        return g
    } 
    //原NFA没有入边但有出边
    else if (!hasInEdges && hasOutEdges) {
        let maxState = pNFA.numOfStates
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(s)
        }
        g.pStateTable[maxState-1].stype = UNMATCH
        g.addState(State(maxState, MATCH))
        for (e in pNFA.pEdgeTable) {
            g.addEdge(e)
        }
        // 添加三条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, maxState, 0, NULL))
        g.addEdge(Edge(maxState-1, 0, 0, NULL))
        g.addEdge(Edge(maxState-1, maxState, 0, NULL))
        return g
    } 
    //原NFA有入边但无出边
    else if (hasInEdges && !hasOutEdges) {
        let maxState = pNFA.numOfStates
        g.addState(State(0, UNMATCH))
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(State(s.stateId+1, s.stype))
        }
        for (e in pNFA.pEdgeTable) {
            g.addEdge(Edge(e.fromState+1, e.nextState+1, e.driverId, e.etype))  
        }
                // 添加三条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, 1, 0, NULL))
        g.addEdge(Edge(0, maxState, 0, NULL))
        g.addEdge(Edge(maxState, 1, 0, NULL))
        return g

    }
    //原NFA既有入边又有出边 
    else {
        let maxState = pNFA.numOfStates + 1
        g.addState(State(0, UNMATCH))
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(State(s.stateId+1, s.stype))
        }
        g.pStateTable[maxState - 1].stype = UNMATCH
        g.addState(State(maxState, MATCH))
        for (e in pNFA.pEdgeTable) {
            g.addEdge(Edge(e.fromState+1, e.nextState+1, e.driverId, e.etype))  
        }
                // 添加三条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, 1, 0, NULL))
        g.addEdge(Edge(0, maxState, 0, NULL))
        g.addEdge(Edge(maxState-1, 1, 0, NULL))
        g.addEdge(Edge(maxState-1, maxState, 0, NULL))
        return g

    }
}

// 0或1 运算：匹配 0 次或 1 次。构造新 NFA，新起始状态 ε 边同时指向原起始状态和新接受状态；原接受状态再添加一条 ε 边到新接受状态
func zeroOrOneNFA(pNFA: Graph): Graph {
    var hasOutEdges = false
    var hasInEdges = false
    let g = Graph(graphIdCounter)
    graphIdCounter += 1

    // 检查 pNFA 的结束状态 是否有出边
    for (e in pNFA.pEdgeTable) {
        if (e.fromState == pNFA.pStateTable[pNFA.numOfStates - 1].stateId) {
            hasOutEdges = true
            break
        }
    }

    // 检查 pNFA2 的初始状态 是否有入边
    for (e in pNFA.pEdgeTable) {
        if (e.nextState == pNFA.pStateTable[0].stateId) {
            hasInEdges = true
            break
        }
    }
    if (!hasInEdges && !hasOutEdges) {
        let maxState = pNFA.numOfStates - 1
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(s)
        }
        for (e in pNFA.pEdgeTable) {
            g.addEdge(e)
        }
        // 添加一条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, maxState, 0, NULL))
        return g
    } else if (!hasInEdges && hasOutEdges) {
        let maxState = pNFA.numOfStates
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(s)
        }
        g.pStateTable[maxState-1].stype = UNMATCH 
        g.addState(State(maxState, MATCH))
        for (e in pNFA.pEdgeTable) {
            g.addEdge(e)
        }
        // 添加一条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, maxState, 0, NULL))
        g.addEdge(Edge(maxState-1, maxState, 0, NULL))
        return g
    } else if (hasInEdges && !hasOutEdges) {
        let maxState = pNFA.numOfStates
        g.addState(State(0, UNMATCH))
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(State(s.stateId, s.stype))
        }
        for (e in pNFA.pEdgeTable) {
            g.addEdge(Edge(e.fromState+1, e.nextState+1, e.driverId, e.etype))
        }
        // 添加一条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, 1, 0, NULL))
        g.addEdge(Edge(0, maxState, 0, NULL))
        return g
    } else {
        let maxState = pNFA.numOfStates + 1
        g.addState(State(0, UNMATCH))
        // 复制所有的状态和边 
        for (s in pNFA.pStateTable) {
            g.addState(State(s.stateId, s.stype))
        }
        g.addState(State(maxState, MATCH))

        for (e in pNFA.pEdgeTable) {
            g.addEdge(Edge(e.fromState+1, e.nextState+1, e.driverId, e.etype))
        }

        // 添加一条空转换的边，头状态到尾状态之间     
        g.addEdge(Edge(0, 1, 0, NULL))
        g.addEdge(Edge(maxState-1, maxState, 0, NULL))
        g.addEdge(Edge(0, maxState, 0, NULL))
        return g
    }
}

// 简单输出 NFA 的状态和边信息
func printGraph(g: Graph) {
    println("Graph ID: ${g.graphId}, Number of States: ${g.numOfStates}\nStates:")
    for (s in g.pStateTable) {
        let stateType : String
        let category : String
        match(s.stype) {
            case StateType.MATCH => stateType = "MATCH"
            case _ => stateType = "UNMATCH"
        }
        match(s.category) {
            case LexemeCategory.KEYWORD => category = "KEYWORD"
            case LexemeCategory.ASSIGNMENT => category = "ASSIGNMENT"
            case LexemeCategory.ID => category = "ID"
            case LexemeCategory.INTERGER_CONST => category = "INTERGER_CONST"
            case LexemeCategory.OPERATORS => category = "OPERATORS"
            case LexemeCategory.WHITESPACE => category = "WHITESPACE"
            case LexemeCategory.SEPARATORS => category = "SEPARATORS"
            case _ => category = ""
        }
        println("  State ${s.stateId} - ${stateType} - ${category}")
    }
    println("Edges:")
    for (e in g.pEdgeTable) {
        match (e.etype) {
            case NULL => println("  Edge from ${e.fromState} to ${e.nextState} via ε")
            case CHAR => println("  Edge from ${e.fromState} to ${e.nextState} via ${Rune(e.driverId)}")
            case CHARSET => println("  Edge from ${e.fromState} to ${e.nextState} via charset:${Int64(e.driverId)}")
        }
    }
    println("--------------------------------------")
}

// move：从 stateSet 中的每个状态出发，查找 NFA 中所有通过输入 symbol 转移的目标状态
func move(nfa: Graph, stateSet: ArrayList<Int64>, symbol: UInt32): ArrayList<Int64> {
    var result: ArrayList<Int64> = ArrayList<Int64>()
    for (s in stateSet) {
        for (e in nfa.pEdgeTable) {
            var etype : String
            match (e.etype) {
                case NULL => etype = "NULL"
                case CHAR => etype = "CHAR"
                case CHARSET => etype = "CHARSET"
            }
            if (e.fromState == s && e.driverId == symbol) {
                result.append(e.nextState)
            }
        }
    }
    return result
}

// epsilonClosure：计算给定状态集合的 ε-闭包
func epsilonClosure(nfa: Graph, stateSet: ArrayList<Int64>): ArrayList<Int64> {
    var closure: HashSet<Int64> = HashSet<Int64>(stateSet)
    var added = true
    while (added) {
        added = false
        var temp: HashSet<Int64> = closure.clone()
        for (s in closure) {
            for (e in nfa.pEdgeTable) {
                var etype : String
                match (e.etype) {
                    case NULL => etype = "NULL"
                    case CHAR => etype = "CHAR"
                    case CHARSET => etype = "CHARSET"
                }
                if (e.fromState == s && etype == "NULL") {
                    if (closure.contains(e.nextState) == false) {
                        temp.put(e.nextState)
                        added = true
                    }
                }
            }
        }
        closure = temp
    }
    var result: ArrayList<Int64> = ArrayList<Int64>(closure)
    result.sort()
    return result
}

// DTran：返回 ε-closure(moveSet(stateSet, symbol))
func DTran(nfa: Graph, stateSet: ArrayList<Int64>, symbol: UInt32): ArrayList<Int64> {
    var mv = move(nfa, stateSet, symbol)
    return epsilonClosure(nfa, mv)
}

// 辅助函数：判断两个状态集合是否相等（已排序）
func equalStateSets(a: ArrayList<Int64>, b: ArrayList<Int64>): Bool {
    return a == b
}

// 辅助函数：从 NFA 图中提取字母表（非 ε 的输入符号），这里仅考虑 CHAR 类型
func getAlphabet(nfa: Graph): ArrayList<UInt32> {
    var alpha: HashSet<UInt32> = HashSet<UInt32>()
    for (e in nfa.pEdgeTable) {
        var etype : String
        match (e.etype) {
            case NULL => etype = "NULL"
            case CHAR => etype = "CHAR"
            case CHARSET => etype = "CHARSET"
        }
        if (etype == "CHAR") {
            alpha.put(e.driverId)
        } else if (etype == "CHARSET") {
            alpha.put(e.driverId)
        }
    }
    return ArrayList<UInt32>(alpha)
}

// NFA_to_DFA：子集构造法
func NFA_to_DFA(nfa: Graph): Graph {
    // 获取 NFA 的字母表
    var alphabet: ArrayList<UInt32> = getAlphabet(nfa)
    
    // 每个 DFA 状态用一个 NFA 状态集合表示
    var dfaStates: ArrayList<ArrayList<Int64>> = ArrayList<ArrayList<Int64>>()
    // 标记 DFA 状态是否已处理
    var marked: ArrayList<Bool> = ArrayList<Bool>()
    
    // 初始 DFA 状态为 ε-closure({NFA起始状态})
    var startSet: ArrayList<Int64> = epsilonClosure(nfa, ArrayList<Int64>([nfa.pStateTable[0].stateId]))
    dfaStates.append(startSet)
    marked.append(false)
    
    // 新建 DFA 图
    var dfa: Graph = Graph(nfa.graphId)
    var dfaStateId: Int64 = 0
    
    // 将 DFA 中的状态与其对应的 NFA 状态集合建立映射：dfaStateIndex -> stateSet
    var dfaMapping: ArrayList<ArrayList<Int64>> = ArrayList<ArrayList<Int64>>()
    dfaMapping.append(startSet)
    
    // 使用队列遍历未处理的 DFA 状态
    var Q: ArrayList<Int64> = ArrayList<Int64>()
    Q.append(0)
    
    // 在 DFA 中添加起始状态
    var isAccept: Bool = false
    for (sid in startSet) {
        for (ns in nfa.pStateTable) {
            var stype : String
            match (ns.stype) {
                case MATCH => stype = "MATCH"
                case UNMATCH => stype = "UNMATCH"
            }
            if (ns.stateId == sid && stype == "MATCH") {
                isAccept = true
                break
            }
        }
        if (isAccept) {break}
    }
    var dfaStart: State
    if (isAccept) {dfaStart = State(dfaStateId, MATCH )}
    else {dfaStart = State(dfaStateId, UNMATCH )}
    dfa.addState(dfaStart)
    dfaStateId++
    
    var dfaTransitions: ArrayList<DFATransition> = ArrayList<DFATransition>()
    
    while (Q.size != 0) {
        var idx: Int64 = Q[0]
        Q.remove(0)
        marked[idx] = true
        // 对于 DFA 状态 idx，对字母表中每个符号计算 DTran
        for (sym in alphabet) {
            var targetSet: ArrayList<Int64> = DTran(nfa, dfaStates[idx], sym)
            if (targetSet.isEmpty()) {continue}
            // 排序 targetSet 便于比较
            targetSet.sort()
            // 查找 targetSet 是否已存在
            var j: Int64 = -1
            for (k in 0..dfaStates.size) {
                if (equalStateSets(dfaStates[k], targetSet)) {
                    j = k
                    break
                }
            }
            if (j == -1) {
                // 新状态
                dfaStates.append(targetSet)
                marked.append(false)
                j = dfaStates.size - 1
                Q.append(j)
                dfaMapping.append(targetSet)
                // 在 DFA 中添加新状态
                var acceptFlag: Bool = false

                for (sid in targetSet) {
                    for (ns in nfa.pStateTable) {
                        var stype : String
                        match (ns.stype) {
                            case MATCH => stype = "MATCH"
                            case UNMATCH => stype = "UNMATCH"
                        }
                        if (ns.stateId == sid && stype == "MATCH") {
                            acceptFlag = true
                            break
                        }
                    }
                    if (acceptFlag) {break}
                }
                var category: LexemeCategory = NONE

                for (sid in targetSet) {
                    for (ns in nfa.pStateTable) {
                        if (ns.stateId == sid && precedence(category) > precedence(ns.category)) {
                            category = ns.category
                            }
                    }   
                }
                var newDfaState: State
                if (acceptFlag) {newDfaState = State(dfaStateId, MATCH)}
                else {newDfaState = State(dfaStateId, UNMATCH)}
                newDfaState.category = category
                newDfaState.stateId = dfaStateId
                dfa.addState(newDfaState)
                dfaStateId++
            }
            // 添加转换：从 idx 到 j，输入 sym
            var transition: DFATransition = DFATransition(idx, sym, j)
            dfaTransitions.append(transition)
        }
    }
    
    // 将 DFA 转换关系添加为边（DFA 中不使用 ε 边）
    for (trans in dfaTransitions) {
        if (trans.symbol>=32) {dfa.addEdge(Edge(trans.from, trans.to, trans.symbol, CHAR))}
        else {dfa.addEdge(Edge(trans.from, trans.to, trans.symbol, CHARSET))}
    }
    
    return dfa
}

func setCategory(nfa: Graph, category: LexemeCategory) {
    nfa.pStateTable[nfa.numOfStates-1].category = category
    return 
}

func precedence(category: LexemeCategory): UInt32{
    match(category) {
        case LexemeCategory.KEYWORD => return 1
        case LexemeCategory.ASSIGNMENT => return 2
        case LexemeCategory.ID => return 3
        case LexemeCategory.INTERGER_CONST => return 4
        case LexemeCategory.OPERATORS => return 5
        case LexemeCategory.SEPARATORS => return 6
        case LexemeCategory.WHITESPACE => return 8
        case _ => return 10
    }
    return 10
}

// 词法分析函数：根据 DFA 解析字符串并输出 Token 列表  
func tokenize(dfa: Graph, inputStr: String): ArrayList<(String, String)> {
    var tokens: ArrayList<(String, String)> = ArrayList<(String, String)>()  // 存储 Token
    // currentStates 为当前 DFA 状态集合，初始为起始状态的 ε-闭包
    var currentStates: ArrayList<Int64> = epsilonClosure(dfa, ArrayList<Int64>([dfa.pStateTable[0].stateId]))
    var startIdx: Int64 = 0      // 当前 Token 起始位置
    var i: Int64 = 0             // 输入字符串索引
    
    while (i < inputStr.size) {
        var c: UInt32 = UInt32(inputStr[i])  // 读取当前字符
        // 调用 move 函数：计算当前状态集合在输入字符 c 下的转移
        var nextStates: ArrayList<Int64> = ArrayList<Int64>()
        for (s in currentStates) {
            for (e in dfa.pEdgeTable) {
                // 如果边的起始状态属于当前状态集合
                if (e.fromState == s) {
                    // 单字符判断：边类型为 DT_CHAR 且 driverId 等于当前字符 c
                    if (e.driverId >= 32 && e.driverId == c) {
                        nextStates.append(e.nextState)
                    }
                    // 字符集判断：边类型为 DT_CHARSET 或者 driverId 小于32（你设定的条件）
                    else if (e.driverId < 32 ) {
                        var found: Bool = false
                        // 遍历全局字符集表，查找驱动 id 为 e.driverId 的所有段
                        for (seg in charSetTable) {
                            if (seg.indexId == e.driverId) {
                                // 判断当前字符 c 是否在该段的范围内
                                if (c >= UInt32(seg.fromChar) && c <= UInt32(seg.toChar)) {
                                    found = true
                                    break
                                }
                            }
                        }
                        if (found) {
                            nextStates.append(e.nextState)
                        }
                    }
                }
            }
        }
        
        if (!nextStates.isEmpty()) {
            // 找到有效转移，则更新当前状态集合并继续向后读取字符
            currentStates = nextStates
            i++
        } else {
            // 当前字符无法匹配，检查当前状态集合是否包含接受状态
            var isMatch: Bool = false
            for (sid in currentStates) {
                for (s in dfa.pStateTable) {
                    var stype: String
                    match (s.stype) {
                        case MATCH   => stype = "MATCH"
                        case UNMATCH => stype = "UNMATCH"
                    }
                    if (s.stateId == sid && stype == "MATCH") {
                        isMatch = true
                        break
                    }
                }
                if (isMatch) { break }
            }
            
            if (isMatch) {
                // 匹配到一个 Token，构造 token 字符串（逐字符拼接）
                var tokenStr: String = ""
                for (j in startIdx .. i) {
                    tokenStr = tokenStr + String(Rune(inputStr[j]))
                }
                // 根据 DFA 状态集合中的优先级决定 token 的类别
                var tokenCategory: String = ""
                var bestPrec: UInt32 = 9999
                for (sid in currentStates) {
                    for (s in dfa.pStateTable) {
                        if (s.stateId == sid) {
                            var prec: UInt32 = precedence(s.category)
                            if (prec < bestPrec) {
                                bestPrec = prec
                                match (s.category) {
                                    case LexemeCategory.KEYWORD         => tokenCategory = "KEYWORD"
                                    case LexemeCategory.ASSIGNMENT      => tokenCategory = "ASSIGNMENT"
                                    case LexemeCategory.ID              => tokenCategory = "ID"
                                    case LexemeCategory.INTERGER_CONST  => tokenCategory = "INTERGER_CONST"
                                    case LexemeCategory.OPERATORS       => tokenCategory = "OPERATORS"
                                    case LexemeCategory.WHITESPACE      => tokenCategory = "WHITESPACE"
                                    case LexemeCategory.SEPARATORS      => tokenCategory = "SEPARATORS"
                                    case _                            => tokenCategory = ""
                                }
                            }
                        }
                    }
                }
                tokens.append((tokenStr, tokenCategory))
                
                // 重置：从当前位置重新开始匹配，当前状态集合初始化为起始状态的 ε-闭包
                startIdx = i
                currentStates = epsilonClosure(dfa, ArrayList<Int64>([dfa.pStateTable[0].stateId]))
            } else {
                // 当前无法匹配，视为非法字符，跳过，并重置匹配状态
                i++
                startIdx = i
                currentStates = epsilonClosure(dfa, ArrayList<Int64>([dfa.pStateTable[0].stateId]))
            }
        }
    }
    
    // 处理输入结束后剩余的部分
    var isMatch: Bool = false
    for (sid in currentStates) {
        for (s in dfa.pStateTable) {
            var stype: String
            match (s.stype) {
                case MATCH   => stype = "MATCH"
                case UNMATCH => stype = "UNMATCH"
            }
            if (s.stateId == sid && stype == "MATCH") {
                isMatch = true
                break
            }
        }
        if (isMatch) { break }
    }
    if (isMatch) {
        var tokenStr: String = ""
        for (j in startIdx .. i) {
            tokenStr = tokenStr + String(Rune(inputStr[j]))
        }
        var tokenCategory: String = ""
        var bestPrec: UInt32 = 9999
        for (sid in currentStates) {
            for (s in dfa.pStateTable) {
                if (s.stateId == sid) {
                    var prec: UInt32 = precedence(s.category)
                    if (prec < bestPrec) {
                        bestPrec = prec
                        match (s.category) {
                            case LexemeCategory.KEYWORD         => tokenCategory = "KEYWORD"
                            case LexemeCategory.ASSIGNMENT      => tokenCategory = "ASSIGNMENT"
                            case LexemeCategory.ID              => tokenCategory = "ID"
                            case LexemeCategory.INTERGER_CONST  => tokenCategory = "INTERGER_CONST"
                            case LexemeCategory.OPERATORS       => tokenCategory = "OPERATORS"
                            case LexemeCategory.WHITESPACE      => tokenCategory = "WHITESPACE"
                            case LexemeCategory.SEPARATORS      => tokenCategory = "SEPARATORS"
                            case _                            => tokenCategory = ""
                        }
                    }
                }
            }
        }
        tokens.append((tokenStr, tokenCategory))
    }
    
    return tokens
}

// // 词法分析函数：根据 DFA 解析字符串并输出 Token 列表 
// func tokenize(dfa: Graph, inputStr: String): ArrayList<(String, String)> {
//     var tokens: ArrayList<(String, String)> = ArrayList<(String, String)>()  // 存储 Token
//     var currentState: Int64 = 0  // DFA 当前状态
//     var startIdx: Int64 = 0      // 当前 Token 起始位置
//     var i: Int64 = 0             // 输入字符串索引
    
//     while (i < inputStr.size) {
//         var c: UInt32 = UInt32(inputStr[i])  // 读取当前字符
//         var nextState: Int64 = -1    // 记录 DFA 的下一个状态
        
//         // 遍历 DFA 规则，查找当前状态下的转移
//         for (e in dfa.pEdgeTable) {
//             if (e.fromState == currentState && e.driverId == c) {
//                 nextState = e.nextState
//                 break
//             } 
//             if (e.fromState == currentState && e.driverId < 32) {
//                 var found: Bool = false
//                 // 遍历全局字符集表，查找驱动 id 为 e.driverId 的所有段
//                 for (seg in charSetTable) {
//                     if (seg.indexId == e.driverId) {
//                         // 判断当前字符 c 是否在该段的范围内
//                         if (c >= UInt32(seg.fromChar) && c <= UInt32(seg.toChar)) {
//                             found = true
//                             break
//                         }
//                     }
//                 }
//                 if (found) {
//                     nextState = e.nextState
//                     break
//                 }
//             }
//         }
        
//         if (nextState != -1) {
//             // 成功找到转移，进入下一个状态
//             currentState = nextState
//             i++
//         } else {
//             // 当前字符无法匹配，检查当前状态是否是终态
//             var isMatch: Bool = false
//             for (s in dfa.pStateTable) {
//                 var stype: String
//                 match (s.stype) {
//                     case MATCH => stype = "MATCH"
//                     case UNMATCH => stype = "UNMATCH"
//                 }
//                 if (s.stateId == currentState && stype == "MATCH") {
//                     isMatch = true
//                     break
//                 }
//             }
            
//             if (isMatch) {
//                 // 匹配到一个 Token，使用临时字符串 tokenStr 逐个字符拼接构造 token
//                 var tokenStr: String = ""
//                 var category: String = ""
//                 for (j in startIdx .. i) {
//                     tokenStr = tokenStr + String(Rune(inputStr[j]))
//                 }
//                 for (ns in dfa.pStateTable) {
//                     if (ns.stateId == currentState) {
//                         match(ns.category) {
//                             case LexemeCategory.KEYWORD => category = "KEYWORD"
//                             case LexemeCategory.ASSIGNMENT => category = "ASSIGNMENT"
//                             case LexemeCategory.ID => category = "ID"
//                             case LexemeCategory.INTERGER_CONST => category = "INTERGER_CONST"
//                             case LexemeCategory.OPERATORS => category = "OPERATORS"
//                             case LexemeCategory.WHITESPACE => category = "WHITESPACE"
//                             case _ => category = ""
//                         }
//                         break
//                     }
//                 }   
//                 tokens.append((tokenStr, category))
                
//                 // 重置匹配状态，尝试解析下一个 Token
//                 startIdx = i
//                 currentState = 0
//             } else {
//                 // 非法字符处理：跳过或报错
//                 startIdx = i + 1
//                 currentState = 0
//                 i++
//             }
//         }
//     }
    
//     // 处理最后一个 Token
//     var isMatch: Bool = false
//     for (s in dfa.pStateTable) {
//         var stype: String
//         match (s.stype) {
//             case MATCH => stype = "MATCH"
//             case UNMATCH => stype = "UNMATCH"
//         }
//         if (s.stateId == currentState && stype == "MATCH") {
//             isMatch = true
//             break
//         }
//     }
//     if (isMatch) {
//         var tokenStr: String = ""
//         var category: String = ""
//         for (j in startIdx .. i) {
//             tokenStr = tokenStr + String(Rune(inputStr[j]))
//         }
//         for (ns in dfa.pStateTable) {
//             if (ns.stateId == currentState) {
//                 match(ns.category) {
//                     case LexemeCategory.KEYWORD => category = "KEYWORD"
//                     case LexemeCategory.ASSIGNMENT => category = "ASSIGNMENT"
//                     case LexemeCategory.ID => category = "ID"
//                     case LexemeCategory.INTERGER_CONST => category = "INTERGER_CONST"
//                     case LexemeCategory.OPERATORS => category = "OPERATORS"
//                     case LexemeCategory.WHITESPACE => category = "WHITESPACE"
//                     case _ => category = ""
//                 }
//                 break
//             }
//         }   
//         tokens.append((tokenStr, category))
//     }
    
//     return tokens
// }
