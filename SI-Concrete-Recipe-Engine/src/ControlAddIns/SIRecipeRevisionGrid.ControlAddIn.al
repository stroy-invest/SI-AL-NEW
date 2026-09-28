controladdin "SI Recipe Revision Grid"
{
    RequestedHeight = 210;
    RequestedWidth = 1100;
    MinimumHeight = 74;
    MinimumWidth = 700;
    MaximumHeight = 310;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts = 'src/ControlAddIns/SIRecipeRevisionGrid.js';
    StartupScript = 'src/ControlAddIns/SIRecipeRevisionGridStartup.js';

    event ControlReady();
    event RevisionOpen(RecipeNo: Text; RevisionNo: Integer);
    event BOMVersionOpen(RecipeNo: Text; RevisionNo: Integer);

    procedure RenderRows(RowsJson: Text);
}
