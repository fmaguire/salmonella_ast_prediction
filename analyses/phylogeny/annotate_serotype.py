import ete3
import copy
import pandas as pd
import seaborn as sns

ast_df = pd.read_pickle('../ast/ast_df.pkl')

tree = ete3.Tree('pangenome_snps.phylip.contree')

bl_misclassified = ['3338', '3126', '3339', '3184']
ac_misclassified = ['3322', '3323', '3352', '3353', '3333', '1769']

def setup_heatmap(tree, tree_style, ast_df):

    for lf in tree:
        for i, abx in enumerate(ast_df):
            value = ast_df.loc[lf.name, abx]
            print(lf.name)
            print(abx)
            print(value)
            print()

            if value == 'R':
                color = 'white'
                label = {'text': abx[0:4], 'color': 'black'}
            elif value == 'I':
                color = 'grey'
                label = ''
            elif value == 'S':
                color = 'black'
                label = ''

            #lf.add_face(ete3.RectFace(15,30, 'teal', color), position="aligned", column = i + 2)
            lf.add_face(ete3.CircleFace(15, color), position="aligned", column = i + 2)

    for i, name in enumerate(ast_df.columns):
        nameF = ete3.TextFace(name, fsize=10)
        nameF.rotation = -90
        tree_style.aligned_header.add_face(nameF, column=i + 2)


metadata = pd.read_pickle('../serotyping/metadata.pkl')
farms = dict(zip(metadata.index, metadata.Farm))
serovars = dict(zip(metadata.index, metadata.Serotype))
for leaf in tree.iter_leaves():
    serovar = serovars[leaf.name]
    #try:
    farm = "  ({})  ".format(farms[leaf.name])
    #except KeyError:
    #    farm = " (NO FARM) "
    leaf.add_features(serovar=serovar, farm=farm)

sns.set_palette('colorblind')
# no support for hsl straight out as far as I can tell
#serovar_colours = {k: v for k,v in zip(aafc_serovar.unique(), current_palette)}

sero_lut = dict(zip(['Kentucky', 'Hadar', 'Heidelberg',
                     'I:4,[5],12:i:', 'Enteritidis',
                     'Typhimurium', 'Thompson', 'None'], sns.color_palette('colorblind').as_hex()))

ts = ete3.TreeStyle()
ts.mode = 'c'
ts.arc_span = 350
#ts.scale = 5000


for n in tree.traverse():
    nstyle = ete3.NodeStyle()
    #nstyle["vt_line_width"] = 2
    #nstyle["hz_line_width"] = 2
    if n.support >= 95:
        nstyle["fgcolor"] = "red"
        nstyle["size"] = 5
    elif n.support < 95:
        nstyle["fgcolor"] = "black"
        nstyle["size"] = 5
    else:
        nstyle["size"] = 0
    n.set_style(nstyle)





#for l in tree.iter_leaves():
#    l.img_style['bgcolor'] = sero_lut[l.serovar]

# hadar
hadar = tree.get_common_ancestor('3125', '3158')
hadar_style = ete3.NodeStyle()
hadar_style['bgcolor'] = sero_lut['Hadar']
hadar.set_style(hadar_style)

# heidelberg
heid = tree.get_common_ancestor('1760', '3342')
heid_style = ete3.NodeStyle()
heid_style['bgcolor'] = sero_lut['Heidelberg']
heid.set_style(heid_style)

# typh
typh = tree.get_common_ancestor('3151', '3199')
typh_style = ete3.NodeStyle()
typh_style['bgcolor'] = sero_lut['Typhimurium']
typh.set_style(typh_style)

typh_node = tree.search_nodes(name='3333')[0]
typh_node.set_style(typh_style)

# i4
i4 = tree.get_common_ancestor('1893', '1792')
i4_style = ete3.NodeStyle()
i4_style['bgcolor'] = sero_lut['I:4,[5],12:i:']
i4.set_style(i4_style)

# kentucky
kent = tree.get_common_ancestor('3336', '3184')
kent_style = ete3.NodeStyle()
kent_style['bgcolor'] = sero_lut['Kentucky']
kent.set_style(kent_style)

kent = tree.get_common_ancestor('3326', '3184')
kent.set_style(kent_style)

#kent = tree.get_common_ancestor('3132', '3317')
#kent.set_style(kent_style)

# Enter sub group
enter = tree.get_common_ancestor('1797', '3303')
enter_style = ete3.NodeStyle()
enter_style['bgcolor'] = sero_lut['Enteritidis']
enter.set_style(enter_style)

enter = tree.search_nodes(name = '1758')[0]
enter.set_style(enter_style)





# reroot on thompson
thompson_node = tree.search_nodes(name='3193')[0]
thompson_node.img_style['bgcolor'] = sero_lut['Thompson']

# highlight the subsampled taxa

#subset_nodes = []
#sub_tree = copy.copy(tree)
#for i in "1760 3125 3145 3193 1778 3126 3166 3333 1797 3132 3179 3339 1893 3142 3186".split():
#    node = tree.search_nodes(name=i)[0]
#    subset_nodes.append(node)
#    #node.name = serovars.loc[node.name, 'Serotype'].replace(',', '_').replace('[', '').replace(']', '').replace(':', '') + '_' + node.name



#sub_tree.prune(subset_nodes)
#with open('../pangenome/anvio_subsample/phylogeny_data.txt', 'w') as fh:
#    fh.write('item_name\tdata_type\tdata_value\n')
#    fh.write('Core_SNP_Phylogeny\tnewick\t{}\n'.format(sub_tree.write(format=1)))
#

#for node in subset_nodes:
#    node.name = "* "+ node.name


tree.set_outgroup(thompson_node)


def layout(node):
    if node.is_leaf():
        if node.name in bl_misclassified:
            name_face = ete3.AttrFace("name", fsize=20, fgcolor='white')
            farm_face = ete3.AttrFace("farm", fsize=20, fgcolor='white')
            #name_face = ete3.AttrFace("name", fsize=20, fgcolor='#b8bab9')
            #farm_face = ete3.AttrFace("farm", fsize=20, fgcolor='#b8bab9')
        elif node.name in ac_misclassified:
            name_face = ete3.AttrFace("name", fsize=20, fgcolor='white')
            farm_face = ete3.AttrFace("farm", fsize=20, fgcolor='white')
        else:
            name_face = ete3.AttrFace("name", fsize=20)
            farm_face = ete3.AttrFace("farm", fsize=20)

        ete3.faces.add_face_to_node(name_face, node, 0, position='aligned')
        ete3.faces.add_face_to_node(farm_face, node, 1, position='aligned')

ts.show_leaf_name = False
ts.layout_fn = layout
setup_heatmap(tree, ts, ast_df)
#ts.show_branch_support = True
#tree.img_style['vt_line_width'] = 2
#tree.img_style['hz_line_width'] = 2


tree.render('phylogenyserotype.pdf', tree_style=ts)
tree.render('phylogenyserotype.svg', tree_style=ts)
