
let my_subset_test0 = subset [2;3;5;7] [1;2;3;4;5;6;7;8]

let my_equal_sets_test0 = equal_sets [1;2;3;4] [4;3;2;1]

let my_set_union_test0 = equal_sets (set_union [1;2;3;4] [2;3;4;5]) [1;2;3;4;5]

let my_set_intersection_test0 =
  equal_sets (set_intersection [1;3;5;7] [2;4;6;8]) []

let my_set_diff_test0 = equal_sets (set_diff [1;3;4] [1]) [3;4]

let my_computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x / 23) 123456667 = 0

type my_reach_nonterminal =
    | Start | B | C | D

let my_reach_rule =  [
  Start, [N B];
  Start, [N C];
  Start, [N D];
  B, [T"$"; N Start];
  C, [T"++"];
  C, [T"--"];
  D, [T"+"];
  D, [T"-"]]

let my_reach = Start, my_rule

let my_reach_test0 =
  filter_reachable (B, List.tl my_reach_rule) = (B, List.tl my_reach_rule)
