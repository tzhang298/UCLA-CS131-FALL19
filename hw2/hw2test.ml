let accept_all string = Some string

type brackets_nonterminals =
  | A | B

let brackets_grammar =
  (A,
    function
      | A ->
        [[T"("; T")"];
         [T"("; T")"; N B];
         [T"("; N A; T ")"]]
      | B ->
        [[T"["; T"]"];
         [T"["; T"]"; N A];
         [T"["; N B; T"]"]
         ])

let frag = [ "(" ; "(" ; ")" ;"[";"]";"(" ;")";")"]

let make_matcher_test =
  ((make_matcher brackets_grammar accept_all frag) = Some[]);;

let make_parser_test = (make_parser brackets_grammar frag =
    Some (Node (A,
       [Leaf "(";
        Node (A,
         [Leaf "("; Leaf ")";
          Node (B, [Leaf "["; Leaf "]"; Node (A, [Leaf "("; Leaf ")"])])]);
        Leaf ")"])));;
