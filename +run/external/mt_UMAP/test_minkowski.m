function test_minkowski(P, closeAll)
if nargin < 2
    closeAll = false;
end
if closeAll
    close all
end
tmplt = ['ust_s1_samusikImported_minkowski_', String.encodeBank(P), '_29D_15nn_3D.mat'];
run_umap_main('s1_samusikImported_29D.csv', 'label_column', 'end', ...
    'label_file', 's1_29D.properties', ...
    'n_components', 3, ...
    'save_template_file', tmplt, ...
    'metric', 'minkowski', ...
    'dist_args', P);
run_umap_main('s2_samusikImported_29D.csv', ...
    'template_file', tmplt, 'label_column', 'end', ...
    'label_file', 's2_samusikImported_29D.properties', ...
    'match_scenarios', 4, ...
    'see_training', true, ...
    'match_table_fig', false, ...
    'match_histogram_fig', false, ...
    'false_positive_negative_plot', true, 'match_supervisors', 3);
