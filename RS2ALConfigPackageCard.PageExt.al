pageextension 50140 "RS2AL_Config. Package Card" extends "Config. Package Card"
{
    actions
    {
        addlast(processing)
        {
            action(CAGSA_CreateALCodeunit)
            {
                Caption = 'Create AL codeunit';
                ApplicationArea = All;
                Image = CodesList;
                ToolTip = 'Create AL codeunit';

                trigger OnAction()
                var
                    CreateALFromRS: Codeunit "RS2AL_Create AL From RS";
                begin
                    CreateALFromRS.CreateALFile(Rec.Code);
                end;
            }
        }
    }
}
