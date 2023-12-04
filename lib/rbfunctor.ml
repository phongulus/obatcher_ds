[@@@warning "-32-26"]

module RbTree (V: Map.OrderedType) = struct
  type colour = Red | Black;;

  type side = Left | Right;;

  type kt = V.t;;

  type 'a node = Leaf | Node of {
    mutable key: V.t;
    mutable tval: 'a;
    mutable colour: colour;
    mutable rl: side;
    mutable bheight: int;
    mutable parent: 'a node;
    mutable left: 'a node;
    mutable right: 'a node
  }

  type 'a t = {
    mutable root: 'a node
  }

  let insert_op_threshold = ref 64
  let search_op_threshold = ref 100
  let height_threshold = ref 6
  let insert_type = ref 1
  let search_type = ref 2

  let compare = V.compare

  let is_leaf n =
    match n with
    | Leaf -> true
    | Node _ -> false

  let is_empty t = t.root = Leaf

  let get_height t =
    match t.root with
    | Leaf -> 0
    | Node n -> n.bheight

  let wrap_node n = {root = n}

  let unwrap_tree t = t.root

  let set_root_node n t = t.root <- n

  let peek n =
    match n with
    | Leaf -> failwith "Peek function: n is a leaf"
    | Node n -> (n.left, n.right)

  let get_node_colour n =
    match n with
    | Leaf -> Black
    | Node n' -> n'.colour

  let get_node_key n =
    match n with
    | Leaf -> failwith "Key function: n is a leaf"
    | Node n' -> n'.key

  let value n =
    match n with
    | Leaf -> failwith "Value function: n is a leaf"
    | Node n' -> n'.tval

  let left n =
    match n with
    | Leaf -> failwith "Left function: n is a leaf"
    | Node n' -> n'.left

  let right n =
    match n with
    | Leaf -> failwith "Right function: n is a leaf"
    | Node n' -> n'.right

  let key n =
    match n with
    | Leaf -> failwith "Key function: n is a leaf"
    | Node n' -> n'.key
  
  let bheight n =
    match n with
    | Leaf -> 1
    | Node n' -> n'.bheight

  let set_bheight n h =
    match n with
    | Leaf -> ()
    | Node n' -> n'.bheight <- h

  let update_bheight n =
    match n with
    | Leaf -> ()
    | Node n' ->
      n'.bheight <- max (bheight @@ left n) (bheight @@ right n)
        + if get_node_colour n = Black then 1 else 0

  let parent n =
    match n with
    | Leaf -> failwith "Parent function: n is a leaf"
    | Node n' -> n'.parent

  let set_parent n p =
    match n with
    | Leaf -> ()
    | Node n' -> n'.parent <- p

  let side n =
    match n with
    | Leaf -> failwith "Side function: n is a leaf"
    | Node n' -> n'.rl

  let set_side n rl =
    match n with
    | Leaf -> ()
    | Node n' -> n'.rl <- rl

  (** Takes in node, side, child. Updates child's parent field as well. *)
  let set_child n s c =
    match n with
    | Leaf -> ()
    | Node n' ->
      match s with
      | Left -> (set_parent c n; set_side c Left; n'.left <- c)
      | Right -> (set_parent c n; set_side c Right; n'.right <- c)

  let set_colour n c =
    match n with
    | Leaf -> ()
    | Node n' -> n'.colour <- c

  let set_colour_and_update_bheight n c =
    match n with
    | Leaf -> ()
    | Node n' ->
      if n'.colour = Black && c = Red then
        n'.bheight <- n'.bheight - 1
      else if n'.colour = Red && c = Black then
        n'.bheight <- n'.bheight + 1;
      n'.colour <- c

  (** Break apart a node, returns (left child, node, right child). The children's parents are set to Leaf, and the parent's children as well. *)
  let expose n =
    match n with
    | Leaf -> failwith "Expose function: n is a leaf"
    | Node n' ->
      set_parent n'.left Leaf;
      set_parent n'.right Leaf;
      let l = n'.left in
      let r = n'.right in
      set_child n Left Leaf;
      set_child n Right Leaf;
      set_bheight n @@ 1 + (if get_node_colour n = Black then 1 else 0);
      (l, n, r)

  let merge_three_nodes nl n nr =
    match n with
    | Leaf -> failwith "Merge three nodes function: n is a leaf"
    | Node _ ->
      set_child n Left nl;
      set_child n Right nr;
      set_bheight n (max (bheight nl) (bheight nr) + if get_node_colour n = Black then 1 else 0)

  let root_node t = t.root

  let num_nodes t =
    let rec aux n =
      match n with
      | Leaf -> 0
      | Node n' -> 1 + aux n'.left + aux n'.right in
    aux t.root

  let flatten t =
    let rec flatten_aux n =
      match n with
      | Leaf -> []
      | Node n' -> (flatten_aux n'.left) @ [(n'.key, n'.tval)] @ (flatten_aux n'.right) in
    flatten_aux t.root

  let new_tree () = {root = Leaf}

  let new_tree_with_node n = {root = n}

  let new_node k v = Node {
    key = k;
    tval = v;
    colour = Red;
    rl = Left;
    bheight = 1;
    parent = Leaf;
    left = Leaf;
    right = Leaf
  }

  let rec search_aux k n =
    match n with
    | Leaf -> None
    | Node n' ->
      if k == n'.key then Some n'.tval
      else if k > n'.key then search_aux k n'.right
      else search_aux k n'.left

  let search k t = search_aux k t.root

  let rotate_left x t =
    let y = right x in
    set_child x Right (left y);
    if left y != Leaf then set_parent (left y) x;
    set_parent y (parent x);
    if parent x = Leaf then t.root <- y
    else if x == left @@ parent x then set_child (parent x) Left y
    else set_child (parent x) Right y;
    set_child y Left x;
    set_bheight x @@ max (bheight @@ left x) (bheight @@ right x)
      + if get_node_colour x = Black then 1 else 0;
    set_bheight y @@ max (bheight @@ left y) (bheight @@ right y)
      + if get_node_colour y = Black then 1 else 0

  let rotate_right x t =
    let y = left x in
    set_child x Left (right y);
    if right y != Leaf then set_parent (right y) x;
    set_parent y (parent x);
    if parent x = Leaf then t.root <- y
    else if x == right @@ parent x then set_child (parent x) Right y
    else set_child (parent x) Left y;
    set_child y Right x;
    set_bheight x @@ max (bheight @@ left x) (bheight @@ right x)
      + if get_node_colour x = Black then 1 else 0;
    set_bheight y @@ max (bheight @@ left y) (bheight @@ right y)
      + if get_node_colour y = Black then 1 else 0

  let fix_tree n t =
    let prev_k = ref n in 
    let k = ref n in
    while get_node_colour (parent !k) = Red && parent (!k) <> Leaf && parent (parent (!k)) <> Leaf do
      if parent !k == right @@ parent @@ parent !k then
        let u = left @@ parent @@ parent !k in
        update_bheight u;
        update_bheight (parent !k);
        update_bheight (parent @@ parent !k);
        if get_node_colour u == Red then begin
          set_colour_and_update_bheight u Black;
          set_colour_and_update_bheight (parent !k) Black;
          set_colour (parent @@ parent !k) Red;
          k := parent @@ parent !k
        end
        else begin
          if !k == left @@ parent !k then begin
            k := parent !k;
            rotate_right !k t;
          end;
          set_colour_and_update_bheight (parent !k) Black;
          set_colour (parent @@ parent !k) Red;
          rotate_left (parent @@ parent !k) t
        end
      else
        let u = right @@ parent @@ parent !k in
        update_bheight u;
        update_bheight (parent !k);
        update_bheight (parent @@ parent !k);
        if get_node_colour u == Red then begin
          set_colour_and_update_bheight u Black;
          set_colour_and_update_bheight (parent !k) Black;
          set_colour (parent @@ parent !k) Red;
          k := parent @@ parent !k
        end
        else begin
          if !k == right @@ parent !k then begin
            k := parent !k;
            rotate_left !k t
          end;
          set_colour_and_update_bheight (parent !k) Black;
          set_colour (parent @@ parent !k) Red;
          rotate_right (parent @@ parent !k) t
        end;
      prev_k := !k;
    done;
    update_bheight t.root;
    set_colour_and_update_bheight t.root Black

  let rec insert_aux new_node current_node t =
    let k = get_node_key new_node in
    match current_node with
    | Leaf -> failwith "This is not supposed to happen"
    | Node n' ->
      if n'.key = k then ()
      else if n'.key > k then
        (if n'.left = Leaf then (set_child current_node Left new_node; fix_tree new_node t)
        else insert_aux new_node n'.left t)
      else if n'.right = Leaf then (set_child current_node Right new_node; fix_tree new_node t)
      else insert_aux new_node n'.right t

  let insert k v t =
    let new_node = new_node k v in
    match new_node with
    | Leaf -> failwith "Can't insert Leaf"
    | Node n ->
      match t.root with
      | Leaf -> (n.colour <- Black; n.bheight <- 2; n.parent <- Leaf; t.root <- new_node)
      | Node _ -> (n.colour <- Red; insert_aux new_node t.root t)

  let rec find_min_node n =
    match n with
    | Leaf -> failwith "Find min node function: n is a leaf"
    | Node n' ->
      if n'.left == Leaf then n
      else find_min_node (n'.left)
  
  (* let rec delete_aux current_node k t =
    if current_node == Leaf then ()
    else if k < key current_node then
      (delete_aux (left current_node) k t)
    else if key current_node < k then
      (delete_aux (right current_node) k t)
    else begin
      let p = parent current_node in
      if left current_node = Leaf then
        (if p == Leaf then
          let (_, _, r) = expose current_node in
          t.root <- r
        else if right p == current_node then
          set_child p Right (right current_node)
        else
          set_child p Left (right current_node))
      else if right current_node = Leaf then
        (if p == Leaf then
          let (l, _, _) = expose current_node in
          t.root <- l
        else if right p == current_node then
          set_child p Right (left current_node)
        else
          set_child p Left (left current_node))
      else
        let min_node = find_min_node (right current_node) in
        match current_node with
        | Leaf -> failwith "impossible error"
        | Node n' ->
          n'.key <- key min_node;
          n'.tval <- tval min_node;
          delete_aux n'.right (key min_node) t
    end *)

  (* let rec get_black_height_aux acc n =
    match n with
    | Leaf -> acc + 1
    | Node n' -> get_black_height_aux (acc + if n'.colour = Black then 1 else 0) n'.left

  let get_black_height n = get_black_height_aux 0 n *)

  let get_rank n = 
    let bh = bheight n in
    if get_node_colour n = Black then 2 * (bh - 1) else 2 * bh - 1

  let rec join_right tl n tr =
    if get_rank tl.root = int_of_float (floor @@ float_of_int (get_rank tr.root) /. 2.) * 2 then
      (set_colour n Red; merge_three_nodes tl.root n tr.root; {root = n})
    else begin
      let (l, mn, r) = expose tl.root in
      let c = get_node_colour mn in
      let ntr = join_right {root = r} n tr in
      merge_three_nodes l mn ntr.root;
      let t'' = {root = mn} in
      if c == Black && get_node_colour (right mn) = Red && get_node_colour (right @@ right mn) = Red then begin
        set_colour_and_update_bheight (right @@ right mn) Black;
        rotate_left mn t''
      end; t''
    end
    ;;

  let rec join_left tl n tr =
    if get_rank tr.root = int_of_float (floor @@ float_of_int (get_rank tl.root) /. 2.) * 2 then
      (set_colour n Red; merge_three_nodes tl.root n tr.root; {root = n})
    else begin
      let (l, mn, r) = expose tr.root in
      let c = get_node_colour mn in
      let ntl = join_left tl n {root = l} in
      merge_three_nodes ntl.root mn r;
      let t'' = {root = mn} in
      if c == Black && get_node_colour (left mn) = Red && get_node_colour (left @@ left mn) = Red then begin
        set_colour_and_update_bheight (left @@ left mn) Black;
        rotate_right mn t''
      end; t''
    end

  let join tl n tr =
    let ctl = int_of_float (floor @@ float_of_int (get_rank tl.root) /. 2.) in
    let ctr = int_of_float (floor @@ float_of_int (get_rank tr.root) /. 2.) in
    if ctl > ctr then
      let nt = join_right tl n tr in
      if get_node_colour nt.root = Red && get_node_colour (right nt.root) = Red then
        set_colour_and_update_bheight nt.root Black;
      nt
    else if ctr > ctl then
      let nt = join_left tl n tr in
      if get_node_colour nt.root = Red && get_node_colour (left nt.root) = Red then
        set_colour_and_update_bheight nt.root Black;
      nt
    else if get_node_colour tl.root = Black && get_node_colour tr.root = Black then
      (set_colour n Red; merge_three_nodes tl.root n tr.root; {root = n})
    else (set_colour n Black; merge_three_nodes tl.root n tr.root; {root = n})

  let rec split t k =
    if t.root = Leaf then ({root = Leaf}, Leaf, {root = Leaf})
    else
      let (l, m, r) = expose t.root in
      if k = key m then ({root = l}, m, {root = r})
      else if k < key m then
        let (ll, b, lr) = split {root = l} k in
        (ll, b, join lr m {root = r})
      else
        let (rl, b, rr) = split {root = r} k in
        (join {root = l} m rl, b, rr)

  (* Inefficient delete function, based on splitting and rejoining the trees *)
  let delete k t =
    let (l, _, r) = split t k in
    let rmin = find_min_node r.root in
    let (_, mn, r') = split r (key rmin) in
    t.root <- (join l mn r').root

  let rec verify_black_depth n = 
    match n with
    | Leaf -> (true, 1) (* Leaves are always Black *)
    | Node n' ->
      let cur_depth = if n'.colour = Black then 1 else 0 in
      let meta_depth = n'.bheight in
      let (lb, ld) = verify_black_depth n'.left in
      let (rb, rd) = verify_black_depth n'.right in
      (* Printf.printf "key:%d, color:%s, metadata:%d, realleft:%d, realright:%d\n" n'.key (if n'.colour == Black then "Black" else "Red") meta_depth ld rd; *)
      if lb && rb && ld = rd
        && ld + cur_depth = meta_depth
      then (true, ld + cur_depth) else (false, ld + cur_depth)

  let rec verify_internal_property n =
    match n with
    | Leaf -> true
    | Node n' ->
      if n'.colour = Red then
        if get_node_colour n'.left = Black && get_node_colour n'.right = Black then
          verify_internal_property n'.left && verify_internal_property n'.right
        else false
      else verify_internal_property n'.left && verify_internal_property n'.right

  let rec verify_parent_metadata n =
    match n with
    | Leaf -> true
    | Node n' ->
      let rb = match n'.right with
      | Leaf -> true
      | Node nrn' -> nrn'.parent = n && nrn'.rl = Right && verify_parent_metadata n'.right in
      if not rb then false else match n'.left with
      | Leaf -> true
      | Node nln' -> nln'.parent = n && nln'.rl = Left && verify_parent_metadata n'.left

  let verify_tree ?(check_root_color=false) t : bool =
    if check_root_color then get_node_colour t.root = Black
    else
      let (bd, _) = verify_black_depth t.root in
      bd
      &&
      verify_internal_property t.root
end