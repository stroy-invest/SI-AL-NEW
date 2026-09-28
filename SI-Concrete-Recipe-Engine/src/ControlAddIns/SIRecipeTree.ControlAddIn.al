controladdin "SI Recipe Tree"
{
    RequestedHeight = 340;
    RequestedWidth = 1100;
    MinimumHeight = 220;
    MinimumWidth = 700;
    MaximumHeight = 520;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts = 'src/ControlAddIns/SIRecipeTree.js';
    StartupScript = 'src/ControlAddIns/SIRecipeTreeStartup.js';

    event ControlReady();
    event NodeSelected(NodeType: Text; RecipeNo: Text);
    event NodeOpen(RecipeNo: Text);

    procedure RenderTree(TreeJson: Text);
    procedure ExpandAll();
    procedure CollapseAll();
    procedure SelectRecipe(RecipeNo: Text);
}
