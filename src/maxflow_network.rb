require './src/network.rb'

class MaxflowNetwork < Network

  attr_reader :seeds
  attr_reader :start
  attr_reader :final

  # 初期化
  def initialize
    super
    @seeds = []
    @start = nil
    @final = nil
  end

  # シードを設定
  # seeds：設定するノードのIDリスト
  def set_seeds(list)
    reset_seeds
    list.each do |l|
      exist = 0
      @nodes.each do |n|
        if n.id == l
          @seeds.push(n)
          exist = 1
        end
      end
      if exist == 0
        puts "error in setseeds(list): node in list is not exist."
        puts "list is "
        p list
        exit(1)
      end
    end
  end

  # Maxflowアルゴリズム
  # 辺容量の限界までflowを流す。
  def maxflow
    init_edge
    set_start
    set_final
    while flow_free_route == 1
    end
  end

  # Maxflowアルゴリズムで得られたコミュニティを返す
  # ２次元配列[[from,to],[from,to]...]を返す。
  # 仮想始点は-1、仮想終点は-2である。
  def get_community
    community = []
    edges = get_community_edges(@start.id)
    edges.each do |e|
      if e.flow <= e.capacity
        community << [e.from, e.to]
      end
    end
    return community
  end

  private

  # シードをリセット
  def reset_seeds
    @seeds = []
  end

  # エッジの初期化
  # 仮想点を含まないエッジの容量をすべてシードの数にする。
  def init_edge
    @edges.each do |e|
      e.flow = 0
      e.capacity = @seeds.size
    end
  end

  # 仮想始点を追加
  # 仮想始点からシードへ容量無限(1000)のエッジを追加する。
  # 仮想始点のノードIDは-1。
  def set_start
    @start = add_node(-1)
    @seeds.each do |s|
      connect(@start.id, s.id, 0, 1000)
    end
  end

  # 仮想終点を追加
  # シードページと仮想始点以外のノードから辺容量１のエッジを追加する。
  def set_final
    @final = add_node(-2)
    nodes = @nodes - @seeds - [@start, @final]
    nodes.each do |n|
      connect(n.id, @final.id, 0, 1)
    end
  end

  # 容量に空きがあるルートにフローを最大まで流す
  # フローを流したら１を返し、なければ０を返す
  def flow_free_route
    route = find_free_route(@start.id)
    if route == nil
      return 0;
    end
    min = 9999
    route.each do |r|
      if min > r.capacity - r.flow
        min = r.capacity - r.flow
      end
    end
    route.each do |r|
      r.flow += min
    end
    return 1
  end

  # 容量に空きのあるルートを再帰的に探す
  # from：接続元のノードID
  # 空きのあるルートが見つかれば、そのエッジ集合を返す
  # 空きのあるルートが見つからなければ、nilを返す
  def find_free_route(from)
    route = []
    if from == @final.id
      return route
    end
    @edges.each do |edge|
      if edge.from == from && edge.flow < edge.capacity
        result = find_free_route(edge.to)
        if result != nil
          route = result
          route << edge
          return route
        end
      end
    end
    return nil
  end

  # Masflowアルゴリズムを適用したグラフからコミュニティを切り離す
  # from：仮想始点のノードID
  # 切り離したコミュニティのエッジ集合を返す。
  def get_community_edges(from)
    edges = []
    @edges.each do |e|
      if e.from == from
        if e.flow < e.capacity
          edges << e
          results = get_community_edges(e.to)
          if results != nil
            results.each do |result|
              edges << result
            end
          end
        end
      end
    end
    if edges.size == 0
      return nil
    end
    edges
  end

end


