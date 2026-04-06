%%%% -*- Mode:Prolog -*-

%%%% test_sssp.pl
%%%%
%%%% Test suite per sssp.pl
%%%% Caricare con: ?- [sssp], [test_sssp].
%%%% Eseguire tutti i test con: ?- run_all_tests.
%%%%
%%%% NOTA: NON includere :- [sssp]. qui dentro.
%%%% Caricare sssp.pl prima separatamente, altrimenti SWI-Prolog
%%%% segnala warning 'Clauses not together' per ogni predicato.
%%%%
%%%% Ogni test stampa PASS o FAIL e ha sempre successo come predicato,
%%%% cosi' run_all_tests non si interrompe in caso di fallimento.



%%%%------------------------------------------------------------------------%%%%
%%%%                        Utilita' di test                                %%%%
%%%%------------------------------------------------------------------------%%%%

%%% assert_true/2
%%% Stampa PASS se Goal ha successo, FAIL altrimenti.
%%% Ha sempre successo come predicato.
assert_true(Name, Goal) :-
    ( call(Goal) ->
        format("PASS: ~w~n", [Name])
    ;
        format("FAIL: ~w~n", [Name])
    ).

%%% assert_false/2
%%% Stampa PASS se Goal fallisce, FAIL altrimenti.
%%% Ha sempre successo come predicato.
assert_false(Name, Goal) :-
    ( call(Goal) ->
        format("FAIL: ~w  (goal inaspettatamente riuscito)~n", [Name])
    ;
        format("PASS: ~w~n", [Name])
    ).

%%% run_test/2
%%% Esegue un test (che puo' anche fallire) e garantisce sempre successo.
run_test(Name, Goal) :-
    ( call(Goal) ->
        true
    ;
        format("  [nota: ~w e' fallito come predicato]~n", [Name])
    ).

%%% Pulisce tutto lo stato lasciato dai test precedenti.
clean_all :-
    retractall(graph(_)),
    retractall(vertex(_, _)),
    retractall(arc(_, _, _, _)),
    retractall(distance(_, _, _)),
    retractall(visited(_, _)),
    retractall(previous(_, _, _)),
    retractall(heap(_, _)),
    retractall(heap_entry(_, _, _, _)).


%%%%------------------------------------------------------------------------%%%%
%%%%                        Test: MinHeap                                   %%%%
%%%%------------------------------------------------------------------------%%%%

test_heap_new :-
    clean_all,
    new_heap(h1),
    assert_true("heap creato",     heap(h1, 0)),
    assert_true("heap vuoto",      empty(h1)),
    assert_false("heap non pieno", not_empty(h1)),
    clean_all.

test_heap_insert_single :-
    clean_all,
    new_heap(h1),
    insert(h1, 5, a),
    assert_true("size dopo insert", heap(h1, 1)),
    assert_true("head corretta",    head(h1, 5, a)),
    assert_true("not_empty",        not_empty(h1)),
    clean_all.

test_heap_insert_order :-
    clean_all,
    new_heap(h1),
    insert(h1, 10, c),
    insert(h1,  3, a),
    insert(h1,  7, b),
    assert_true("head e' il minimo", head(h1, 3, a)),
    clean_all.

test_heap_extract :-
    clean_all,
    new_heap(h1),
    insert(h1, 10, c),
    insert(h1,  3, a),
    insert(h1,  7, b),
    extract(h1, K1, V1),
    extract(h1, K2, V2),
    extract(h1, K3, V3),
    assert_true("primo estratto chiave",   K1 =:= 3),
    assert_true("primo estratto valore",   V1 == a),
    assert_true("secondo estratto chiave", K2 =:= 7),
    assert_true("secondo estratto valore", V2 == b),
    assert_true("terzo estratto chiave",   K3 =:= 10),
    assert_true("terzo estratto valore",   V3 == c),
    assert_true("heap vuoto dopo extract", empty(h1)),
    clean_all.

test_heap_modify_key :-
    clean_all,
    new_heap(h1),
    insert(h1, 10, a),
    insert(h1, 20, b),
    insert(h1, 30, c),
    modify_key(h1, 5, 30, c),
    assert_true("dopo modify_key testa e' c", head(h1, 5, c)),
    clean_all.

test_heap_inf :-
    clean_all,
    new_heap(h1),
    insert(h1, inf, x),
    insert(h1, 0,   y),
    assert_true("0 < inf: testa e' y", head(h1, 0, y)),
    extract(h1, _, _),
    assert_true("dopo extract testa inf", head(h1, inf, x)),
    clean_all.

test_heap_delete :-
    clean_all,
    new_heap(h1),
    insert(h1, 1, a),
    delete_heap(h1),
    assert_false("heap eliminato", heap(h1, _)),
    clean_all.

test_heap_many_inserts :-
    clean_all,
    new_heap(hh),
    insert(hh, 50, e50),
    insert(hh, 10, e10),
    insert(hh, 30, e30),
    insert(hh, 20, e20),
    insert(hh, 40, e40),
    extract(hh, K1, _),
    extract(hh, K2, _),
    extract(hh, K3, _),
    extract(hh, K4, _),
    extract(hh, K5, _),
    assert_true("extract in ordine 1", K1 =:= 10),
    assert_true("extract in ordine 2", K2 =:= 20),
    assert_true("extract in ordine 3", K3 =:= 30),
    assert_true("extract in ordine 4", K4 =:= 40),
    assert_true("extract in ordine 5", K5 =:= 50),
    clean_all.


%%%%------------------------------------------------------------------------%%%%
%%%%                        Test: API Grafi                                 %%%%
%%%%------------------------------------------------------------------------%%%%

test_new_graph :-
    clean_all,
    new_graph(g),
    assert_true("grafo esiste", graph(g)),
    new_graph(g),
    assert_true("idempotente: ancora un grafo",
                (findall(X, graph(X), L), length(L, 1))),
    clean_all.

test_delete_graph :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    new_arc(g, a, b, 3),
    delete_graph(g),
    assert_false("grafo eliminato",   graph(g)),
    assert_false("vertici eliminati", vertex(g, _)),
    assert_false("archi eliminati",   arc(g, _, _, _)),
    clean_all.

test_new_vertex :-
    clean_all,
    new_graph(g),
    new_vertex(g, v1),
    assert_true("vertice esiste", vertex(g, v1)),
    new_vertex(g, v1),
    assert_true("idempotente: un solo v1",
                (findall(X, vertex(g, X), L), length(L, 1))),
    clean_all.

test_new_arc_basic :-
    clean_all,
    new_graph(g),
    new_vertex(g, u),
    new_vertex(g, v),
    new_arc(g, u, v, 4),
    assert_true("arco esiste con peso 4", arc(g, u, v, 4)),
    clean_all.

test_new_arc_default_weight :-
    clean_all,
    new_graph(g),
    new_vertex(g, u),
    new_vertex(g, v),
    new_arc(g, u, v),
    assert_true("peso default 1", arc(g, u, v, 1)),
    clean_all.

test_new_arc_replace :-
    clean_all,
    new_graph(g),
    new_vertex(g, u),
    new_vertex(g, v),
    new_arc(g, u, v, 4),
    new_arc(g, u, v, 9),
    assert_true("arco aggiornato a 9",  arc(g, u, v, 9)),
    assert_false("vecchio peso 4 assente", arc(g, u, v, 4)),
    clean_all.

test_new_arc_creates_vertices :-
    clean_all,
    new_graph(g),
    new_arc(g, x, y, 2),
    assert_true("vertice x creato", vertex(g, x)),
    assert_true("vertice y creato", vertex(g, y)),
    clean_all.

test_vertices_list :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    new_vertex(g, c),
    vertices(g, Vs),
    assert_true("3 vertici", length(Vs, 3)),
    clean_all.

test_arcs_list :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    new_arc(g, a, b, 1),
    new_arc(g, b, a, 2),
    arcs(g, Es),
    assert_true("2 archi", length(Es, 2)),
    clean_all.

test_neighbors :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    new_vertex(g, c),
    new_arc(g, a, b, 1),
    new_arc(g, a, c, 2),
    neighbors(g, a, Ns),
    assert_true("2 vicini di a",  length(Ns, 2)),
    neighbors(g, b, Nb),
    assert_true("0 vicini di b",  length(Nb, 0)),
    clean_all.


%%%%------------------------------------------------------------------------%%%%
%%%%                        Test: Dijkstra — grafo progetto                 %%%%
%%%%------------------------------------------------------------------------%%%%

setup_project_graph :-
    clean_all,
    test(proj).

test_dijkstra_distances :-
    setup_project_graph,
    dijkstra_sssp(proj, r),
    assert_true("dist r=0",  distance(proj, r, 0)),
    assert_true("dist s=5",  distance(proj, s, 5)),
    assert_true("dist t=3",  distance(proj, t, 3)),
    assert_true("dist x=8",  distance(proj, x, 8)),
    assert_true("dist y=7",  distance(proj, y, 7)),
    assert_true("dist z=10", distance(proj, z, 10)),
    clean_all.

test_dijkstra_visited :-
    setup_project_graph,
    dijkstra_sssp(proj, r),
    assert_true("r visitato", visited(proj, r)),
    assert_true("s visitato", visited(proj, s)),
    assert_true("t visitato", visited(proj, t)),
    assert_true("x visitato", visited(proj, x)),
    assert_true("y visitato", visited(proj, y)),
    assert_true("z visitato", visited(proj, z)),
    clean_all.

test_shortest_path_r_to_z :-
    %%% Cammino ottimo r->z: r->s(5)->x(8)->z(10). 3 archi.
    %%% (r->t->z = 3+8=11, r->s->x->z = 5+3+2=10 => ottimo via s)
    setup_project_graph,
    dijkstra_sssp(proj, r),
    shortest_path(proj, r, z, Path),
    assert_true("path r->z ha 3 archi", length(Path, 3)),
    ( Path = [arc(proj, r, s, 5) | _] ->
        format("PASS: path r->z inizia con r->s~n")
    ;
        format("FAIL: path r->z inizia con r->s~n")
    ),
    clean_all.

test_shortest_path_r_to_y :-
    %%% Cammino ottimo r->t->y = 3+4=7: 2 archi.
    %%% (r->s->x->y = 5+3+1=9 > 7)
    setup_project_graph,
    dijkstra_sssp(proj, r),
    shortest_path(proj, r, y, Path),
    assert_true("path r->y ha 2 archi", length(Path, 2)),
    ( Path = [arc(proj, r, t, 3), arc(proj, t, y, 4)] ->
        format("PASS: path r->y e' r->t->y~n")
    ;
        format("FAIL: path r->y e' r->t->y~n")
    ),
    clean_all.

test_shortest_path_source_to_source :-
    setup_project_graph,
    dijkstra_sssp(proj, r),
    shortest_path(proj, r, r, Path),
    assert_true("path r->r e' vuota", Path == []),
    clean_all.

test_dijkstra_idempotent :-
    setup_project_graph,
    dijkstra_sssp(proj, r),
    dijkstra_sssp(proj, r),
    assert_true("dist r=0 dopo doppia exec",  distance(proj, r, 0)),
    assert_true("dist z=10 dopo doppia exec", distance(proj, z, 10)),
    clean_all.


%%%%------------------------------------------------------------------------%%%%
%%%%                        Test: Edge Cases                                %%%%
%%%%------------------------------------------------------------------------%%%%

test_single_vertex :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    dijkstra_sssp(g, a),
    assert_true("dist a=0", distance(g, a, 0)),
    shortest_path(g, a, a, Path),
    assert_true("path a->a vuoto", Path == []),
    clean_all.

test_disconnected_graph :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    dijkstra_sssp(g, a),
    assert_true("dist a=0",   distance(g, a, 0)),
    assert_true("dist b=inf", distance(g, b, inf)),
    clean_all.

test_disconnected_path_fails :-
    clean_all,
    new_graph(g),
    new_vertex(g, a),
    new_vertex(g, b),
    dijkstra_sssp(g, a),
    assert_false("path a->b inesistente fallisce",
                 shortest_path(g, a, b, _)),
    clean_all.

test_two_graphs_independent :-
    clean_all,
    new_graph(g1),
    new_vertex(g1, a), new_vertex(g1, b),
    new_arc(g1, a, b, 3),
    new_graph(g2),
    new_vertex(g2, a), new_vertex(g2, b),
    new_arc(g2, a, b, 99),
    dijkstra_sssp(g1, a),
    dijkstra_sssp(g2, a),
    assert_true("dist g1 a->b = 3",  distance(g1, b, 3)),
    assert_true("dist g2 a->b = 99", distance(g2, b, 99)),
    clean_all.

test_arc_weight_zero :-
    clean_all,
    new_graph(g),
    new_vertex(g, a), new_vertex(g, b),
    new_arc(g, a, b, 0),
    dijkstra_sssp(g, a),
    assert_true("dist b=0 con arco peso 0", distance(g, b, 0)),
    clean_all.

test_arc_weight_float :-
    clean_all,
    new_graph(g),
    new_vertex(g, a), new_vertex(g, b),
    new_arc(g, a, b, 4.2),
    dijkstra_sssp(g, a),
    assert_true("dist b=4.2", distance(g, b, 4.2)),
    clean_all.

test_multiple_paths_shortest_chosen :-
    %%% Due cammini: a->b->c (1+1=2) e a->c (10). Deve scegliere peso 2.
    clean_all,
    new_graph(g),
    new_vertex(g, a), new_vertex(g, b), new_vertex(g, c),
    new_arc(g, a, b, 1),
    new_arc(g, b, c, 1),
    new_arc(g, a, c, 10),
    dijkstra_sssp(g, a),
    assert_true("dist c=2 (cammino ottimo)", distance(g, c, 2)),
    shortest_path(g, a, c, Path),
    assert_true("path a->c ha 2 archi", length(Path, 2)),
    clean_all.

test_arc_replace_affects_dijkstra :-
    clean_all,
    new_graph(g),
    new_vertex(g, a), new_vertex(g, b),
    new_arc(g, a, b, 100),
    new_arc(g, a, b, 1),
    dijkstra_sssp(g, a),
    assert_true("dist b=1 dopo sostituzione arco", distance(g, b, 1)),
    clean_all.

test_linear_chain :-
    %%% Catena a->b->c->d: distanze cumulative.
    clean_all,
    new_graph(g),
    new_vertex(g, a), new_vertex(g, b),
    new_vertex(g, c), new_vertex(g, d),
    new_arc(g, a, b, 1),
    new_arc(g, b, c, 2),
    new_arc(g, c, d, 3),
    dijkstra_sssp(g, a),
    assert_true("dist b=1", distance(g, b, 1)),
    assert_true("dist c=3", distance(g, c, 3)),
    assert_true("dist d=6", distance(g, d, 6)),
    shortest_path(g, a, d, Path),
    assert_true("path a->d ha 3 archi", length(Path, 3)),
    clean_all.


%%%%------------------------------------------------------------------------%%%%
%%%%                        Runner                                          %%%%
%%%%------------------------------------------------------------------------%%%%

%%% Esegue un singolo test garantendo sempre successo (per non bloccare il runner).
safe_run(Test) :-
    ( call(Test) -> true ; true ).

run_all_tests :-
    nl,
    format("=== TEST MINHEAP ===~n"),
    safe_run(test_heap_new),
    safe_run(test_heap_insert_single),
    safe_run(test_heap_insert_order),
    safe_run(test_heap_extract),
    safe_run(test_heap_modify_key),
    safe_run(test_heap_inf),
    safe_run(test_heap_delete),
    safe_run(test_heap_many_inserts),

    nl,
    format("=== TEST API GRAFI ===~n"),
    safe_run(test_new_graph),
    safe_run(test_delete_graph),
    safe_run(test_new_vertex),
    safe_run(test_new_arc_basic),
    safe_run(test_new_arc_default_weight),
    safe_run(test_new_arc_replace),
    safe_run(test_new_arc_creates_vertices),
    safe_run(test_vertices_list),
    safe_run(test_arcs_list),
    safe_run(test_neighbors),

    nl,
    format("=== TEST DIJKSTRA (grafo progetto) ===~n"),
    safe_run(test_dijkstra_distances),
    safe_run(test_dijkstra_visited),
    safe_run(test_shortest_path_r_to_z),
    safe_run(test_shortest_path_r_to_y),
    safe_run(test_shortest_path_source_to_source),
    safe_run(test_dijkstra_idempotent),

    nl,
    format("=== TEST EDGE CASES ===~n"),
    safe_run(test_single_vertex),
    safe_run(test_disconnected_graph),
    safe_run(test_disconnected_path_fails),
    safe_run(test_two_graphs_independent),
    safe_run(test_arc_weight_zero),
    safe_run(test_arc_weight_float),
    safe_run(test_multiple_paths_shortest_chosen),
    safe_run(test_arc_replace_affects_dijkstra),
    safe_run(test_linear_chain),

    nl,
    format("=== FINE TEST ===~n").

%%%% end of file test_sssp.pl
