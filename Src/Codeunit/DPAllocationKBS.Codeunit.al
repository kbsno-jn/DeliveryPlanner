namespace Knowit.DeliveryPlanner;

codeunit 62106 "DP Allocation KBS"
{
    procedure Allocate(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Available: Decimal)
    var
        TempSourceBuffer: Record "DP Allocation Buffer KBS" temporary;
        TempWorkBuffer: Record "DP Allocation Buffer KBS" temporary;
        Remaining: Decimal;
        TotalNeed: Decimal;
        TotalWeight: Decimal;
        Share: Decimal;
        CappedAny: Boolean;
    begin
        TempSourceBuffer.Copy(TempBuffer, true);
        TempSourceBuffer.Reset();
        if not TempSourceBuffer.FindSet() then
            exit;
        repeat
            TempWorkBuffer := TempSourceBuffer;
            if TempWorkBuffer.Increment <= 0 then
                Error(PositiveIncrementErr, TempWorkBuffer."Location Code");
            if TempWorkBuffer.Weight <= 0 then
                Error(PositiveWeightErr, TempWorkBuffer."Location Code");
            TempWorkBuffer.Need := Round(Maximum(0, TempWorkBuffer.Need), TempWorkBuffer.Increment, '<');
            TempWorkBuffer.Allocation := 0;
            TempWorkBuffer."Ideal Allocation" := 0;
            TempWorkBuffer.Insert();
            TempSourceBuffer.Allocation := 0;
            TempSourceBuffer."Ideal Allocation" := 0;
            TempSourceBuffer.Modify();
            TotalNeed += TempWorkBuffer.Need;
            if TempWorkBuffer.Need > 0 then
                TotalWeight += TempWorkBuffer.Weight;
        until TempSourceBuffer.Next() = 0;

        Remaining := Minimum(Maximum(0, Available), TotalNeed);
        if Remaining = 0 then
            exit;

        // Each saturation pass removes at least one store. The work depends on
        // the number of stores, never on the number of units being allocated.
        repeat
            CappedAny := false;
            if TotalWeight > 0 then begin
                Share := Remaining / TotalWeight;
                if TempWorkBuffer.FindSet() then
                    repeat
                        if (TempWorkBuffer.Need > 0) and (TempWorkBuffer."Ideal Allocation" = 0) then
                            if TempWorkBuffer.Need <= Share * TempWorkBuffer.Weight then begin
                                TempWorkBuffer."Ideal Allocation" := TempWorkBuffer.Need;
                                TempWorkBuffer.Modify();
                                Remaining -= TempWorkBuffer.Need;
                                TotalWeight -= TempWorkBuffer.Weight;
                                CappedAny := true;
                            end;
                    until TempWorkBuffer.Next() = 0;
            end;
        until (not CappedAny) or (TotalWeight = 0);

        if TotalWeight > 0 then begin
            Share := Remaining / TotalWeight;
            if TempWorkBuffer.FindSet() then
                repeat
                    if (TempWorkBuffer.Need > 0) and (TempWorkBuffer."Ideal Allocation" = 0) then begin
                        TempWorkBuffer."Ideal Allocation" := Minimum(TempWorkBuffer.Need, Share * TempWorkBuffer.Weight);
                        TempWorkBuffer.Modify();
                    end;
                until TempWorkBuffer.Next() = 0;
        end;

        Remaining := Minimum(Maximum(0, Available), TotalNeed);
        if TempWorkBuffer.FindSet() then
            repeat
                TempWorkBuffer.Allocation := Round(TempWorkBuffer."Ideal Allocation", TempWorkBuffer.Increment, '<');
                Remaining -= TempWorkBuffer.Allocation;
                TempWorkBuffer.Modify();
            until TempWorkBuffer.Next() = 0;
        DistributeRemainder(TempWorkBuffer, Remaining);
        if TempWorkBuffer.FindSet() then
            repeat
                TempSourceBuffer.Get(TempWorkBuffer."Location Code");
                TempSourceBuffer.Allocation := TempWorkBuffer.Allocation;
                TempSourceBuffer."Ideal Allocation" := TempWorkBuffer."Ideal Allocation";
                TempSourceBuffer.Modify();
            until TempWorkBuffer.Next() = 0;
    end;

    local procedure DistributeRemainder(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Remaining: Decimal)
    var
        BestLocation: Code[10];
        BestRemainder: Decimal;
        BestWeight: Decimal;
        RelativeRemainder: Decimal;
        RoundQuantity: Decimal;
        FullRounds: Decimal;
        CapacityRounds: Decimal;
        Found: Boolean;
    begin
        repeat
            Found := false;
            Clear(BestLocation);
            BestRemainder := 0;
            BestWeight := 0;
            RoundQuantity := 0;
            CapacityRounds := 0;
            if TempBuffer.FindSet() then
                repeat
                    if (TempBuffer.Increment <= Remaining) and (TempBuffer.Allocation + TempBuffer.Increment <= TempBuffer.Need) then begin
                        RoundQuantity += TempBuffer.Increment;
                        if CapacityRounds = 0 then
                            CapacityRounds := Round((TempBuffer.Need - TempBuffer.Allocation) / TempBuffer.Increment, 1, '<')
                        else
                            CapacityRounds := Minimum(CapacityRounds, Round((TempBuffer.Need - TempBuffer.Allocation) / TempBuffer.Increment, 1, '<'));
                        RelativeRemainder := (TempBuffer."Ideal Allocation" - TempBuffer.Allocation) / TempBuffer.Increment;
                        if (not Found) or (RelativeRemainder > BestRemainder) or
                           ((RelativeRemainder = BestRemainder) and (TempBuffer.Weight > BestWeight)) or
                           ((RelativeRemainder = BestRemainder) and (TempBuffer.Weight = BestWeight) and (TempBuffer."Location Code" < BestLocation))
                        then begin
                            Found := true;
                            BestLocation := TempBuffer."Location Code";
                            BestRemainder := RelativeRemainder;
                            BestWeight := TempBuffer.Weight;
                        end;
                    end;
                until TempBuffer.Next() = 0;
            if Found then begin
                FullRounds := Minimum(CapacityRounds, Round(Remaining / RoundQuantity, 1, '<'));
                if FullRounds > 0 then begin
                    // Normalized remainders differ by less than one. Every
                    // eligible store therefore receives one step before any
                    // receives its next step. Apply complete rounds together,
                    // even when a large unavailable pack leaves millions of
                    // small feasible units to distribute.
                    if TempBuffer.FindSet() then
                        repeat
                            if (TempBuffer.Increment <= Remaining) and (TempBuffer.Allocation + TempBuffer.Increment <= TempBuffer.Need) then begin
                                TempBuffer.Allocation += FullRounds * TempBuffer.Increment;
                                TempBuffer.Modify();
                            end;
                        until TempBuffer.Next() = 0;
                    Remaining -= FullRounds * RoundQuantity;
                end else begin
                    TempBuffer.Get(BestLocation);
                    TempBuffer.Allocation += TempBuffer.Increment;
                    Remaining -= TempBuffer.Increment;
                    TempBuffer.Modify();
                end;
            end;
        until not Found;
    end;

    local procedure Minimum(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left < Right then
            exit(Left);
        exit(Right);
    end;

    local procedure Maximum(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left > Right then
            exit(Left);
        exit(Right);
    end;

    var
        PositiveIncrementErr: Label 'Antallstrinnet må være større enn null for lokasjon %1.', Comment = '%1 = Location code';
        PositiveWeightErr: Label 'Fordelingsvekten må være større enn null for lokasjon %1.', Comment = '%1 = Location code';
}
