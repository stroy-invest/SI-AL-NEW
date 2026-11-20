page 50291 "SI Hierarchy Height Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Тест висоти дерева товарів';
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(Hierarchy; "SI Adaptive Item Hierarchy")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    // Intentionally no data loading: isolate host layout behavior.
                    // No changes to the production page or shared control add-in.
                end;
            }
        }
    }
}
