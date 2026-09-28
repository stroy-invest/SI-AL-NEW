pageextension 52033 "SI Bus. Manager RC" extends "Business Manager Role Center"
{
    layout
    {
        addfirst(RoleCenter)
        {
            part(SIApproverNotificationCues; "SI Approver Notification Cues")
            {
                ApplicationArea = All;
            }

            part(SIMyApprovals; "SI My Approvals Cues")
            {
                ApplicationArea = All;
            }
        }
    }
}