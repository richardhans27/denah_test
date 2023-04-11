import 'dart:collection';
import 'package:denah_test/models/node.dart';

class ShortestPath{
  Node start, end;

  ShortestPath({
    required this.start,
    required this.end,
  });

 // BFS traversal that updates the dist and parent vector
  Iterable<Node> pathSearch(){
    Queue<Node> queue = Queue<Node>();// queue to store nodes to be visited along the breadth
   
    
    start.visited = true;   // mark source node as visitedi
    queue.add(start); // push src node to queue

    while(queue.isNotEmpty){
      Node currentNode = queue.removeFirst();// traverse all nodes along the breadth
     // traverse along the node's breadth
      for(var node in currentNode.neighbors){
        if(!node.visited){
          node.visited = true;// // mark it visited
          queue.add(node);
          node.prev = currentNode;
          if(node == end){
            queue.clear();
            break;
          }
        }
      }
    }
    return traceRoute();
  }

  // function that computes the shortest path and prints it
  Iterable<Node> traceRoute(){
    Node? node = end;
    List<Node> route = [];
    //Loop until node is null to reach start node
    //becasue start.prev == null
    while(node != null){
      route.add(node);
      node = node.prev;
    }
    //Reverse the route - bring start to the front
    //Output the route
    // printResult(route.reversed);
    return route.reversed;
  }

  void printResult(Iterable<Node> data){
    for(var x in data){
      print("${x.name} -> ");
    }
  }

  // Iterable<Node> dStarLite(Node start, Node end){
  //   Queue<Node> open_list = Queue<Node>();
  //   Queue<Node> closed_list = Queue<Node>();

  //   List<dynamic> g = [];
  //   List<dynamic> parents = [];

  //   open_list.add(start);
  //   g[start.cost] = 0;

  //   parents = [];
  //   parents[start] = start;

  //   while(open_list.isNotEmpty){
  //     var n = null;

  //     //find a node with the lowest value of f() - evaluation function
  //     for (var v in open_list){
  //       if(n == null || v.cost + h(v) < g[n] + h(n)){
  //         n = v;
  //       }

  //       if(n == null){
  //         print('Path does not exist!');
  //         return [];
  //       }

  //       if(n == end){
  //         List<Node> reconst_path = [];

  //         while(parents[n] != n){
  //           reconst_path.add(n);
  //           n = parents[n];
  //         }
  //         reconst_path.add(start);

  //         return reconst_path.reversed;
  //       }

  //       //for all neighbors of the current node do
  //       for(var m in n.neighbors){
  //         //if the current node isn't in both open_list and closed_list
  //         //add it to open_list and note n as it's parent
  //         if(open_list.any((element) => element == m) && closed_list.any((element) => element == m)){
  //           open_list.add(m);
  //           parents[m] = n;
  //           g[m] = g[n] + weight;
  //         } 
  //         //otherwise, check if it's quicker to first visit n, then m
  //         //and if it is, update parent data and g data
  //         //and if the node was in the closed_list, move it to open_list
  //         else{
  //           if(g[m] > g[n] + weight){
  //             g[m] = g[n] + weight;
  //             parents[m] = n;

  //             if(var m in closed_list){
  //               closed_list.remove(m);
  //               open_list.add(m);
  //             }
  //           }
  //         }
  //       }
  //       //remove n from the open_list, and add it to closed_list
  //       //because all of his neighbors were inspected
  //       open_list.remove(n);
  //       closed_list.add(n);
  //     }
  //   }  
  // }
}