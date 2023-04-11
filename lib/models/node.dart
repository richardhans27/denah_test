class Node {
  List<Node> neighbors;
  bool visited;
  Node? prev;
  String name;
  int cost;
  String type;

  Node({
    required this.neighbors,
    this.visited = false,
    this.prev,
    required this.name,
    this.cost = 1,
    required this.type,
  });

  void addNeighbor(Node node){
    neighbors.add(node);
    node.neighbors.add(this);
  }

  //Node representation
  String getName(){
    return name;
  }
}

