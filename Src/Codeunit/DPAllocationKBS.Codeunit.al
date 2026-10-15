namespace Knowit.DeliveryPlanner;

codeunit 78906 "DP Allocation KBS"
{
    /// <summary>
    /// Distributes the available quantity so that the stores' days of cover are levelled, starting
    /// with the store that runs out first. Days of cover = (Position + allocation) / Daily Rate. No
    /// store receives more than its need, and the result is rounded down to each store's increment.
    /// </summary>
    procedure Allocate(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Available: Decimal)
    var
        TempSourceBuffer: Record "DP Allocation Buffer KBS" temporary;
        TempWorkBuffer: Record "DP Allocation Buffer KBS" temporary;
        Remaining: Decimal;
        TotalNeed: Decimal;
        Level: Decimal;
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
            if (TempWorkBuffer.Need > 0) and (TempWorkBuffer."Daily Rate" <= 0) then
                Error(PositiveRateErr, TempWorkBuffer."Location Code");
            TempWorkBuffer.Allocation := 0;
            TempWorkBuffer."Ideal Allocation" := 0;
            TempWorkBuffer.Insert();
            TempSourceBuffer.Allocation := 0;
            TempSourceBuffer."Ideal Allocation" := 0;
            TempSourceBuffer.Modify();
            TotalNeed += TempWorkBuffer.Need;
        until TempSourceBuffer.Next() = 0;

        Remaining := Minimum(Maximum(0, Available), TotalNeed);
        if Remaining = 0 then
            exit;

        if Remaining = TotalNeed then
            Level := 0
        else
            Level := FindCoverLevel(TempWorkBuffer, Remaining);
        if TempWorkBuffer.FindSet() then
            repeat
                if TempWorkBuffer.Need > 0 then begin
                    if Remaining = TotalNeed then
                        TempWorkBuffer."Ideal Allocation" := TempWorkBuffer.Need
                    else
                        TempWorkBuffer."Ideal Allocation" := AllocationAtLevel(TempWorkBuffer, Level);
                    TempWorkBuffer.Modify();
                end;
            until TempWorkBuffer.Next() = 0;

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

    /// <summary>
    /// Finds the highest common days-of-cover level whose total allocation does not exceed Quantity.
    /// The total is monotone in the level, so bisection converges regardless of store count.
    /// </summary>
    local procedure FindCoverLevel(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Quantity: Decimal): Decimal
    var
        Low: Decimal;
        High: Decimal;
        Middle: Decimal;
        Initialized: Boolean;
        Iteration: Integer;
    begin
        if TempBuffer.FindSet() then
            repeat
                if TempBuffer.Need > 0 then
                    if not Initialized then begin
                        Low := TempBuffer.Position / TempBuffer."Daily Rate";
                        High := (TempBuffer.Position + TempBuffer.Need) / TempBuffer."Daily Rate";
                        Initialized := true;
                    end else begin
                        Low := Minimum(Low, TempBuffer.Position / TempBuffer."Daily Rate");
                        High := Maximum(High, (TempBuffer.Position + TempBuffer.Need) / TempBuffer."Daily Rate");
                    end;
            until TempBuffer.Next() = 0;

        for Iteration := 1 to 200 do begin
            Middle := (Low + High) / 2;
            if (Middle = Low) or (Middle = High) then
                break;
            if TotalAtLevel(TempBuffer, Middle) <= Quantity then
                Low := Middle
            else
                High := Middle;
        end;
        exit(SolveLevelInSegment(TempBuffer, Quantity, Low, High));
    end;

    /// <summary>
    /// Between Low and High the total is linear, so the exact level can be solved directly. This keeps
    /// equal remainders equal, letting the weight decide ties instead of bisection noise.
    /// </summary>
    local procedure SolveLevelInSegment(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Quantity: Decimal; Low: Decimal; High: Decimal): Decimal
    var
        Fixed: Decimal;
        ActivePosition: Decimal;
        ActiveRate: Decimal;
        Level: Decimal;
    begin
        if TempBuffer.FindSet() then
            repeat
                if TempBuffer.Need > 0 then
                    if (TempBuffer.Position + TempBuffer.Need) / TempBuffer."Daily Rate" <= Low then
                        Fixed += TempBuffer.Need
                    else
                        if TempBuffer.Position / TempBuffer."Daily Rate" < High then begin
                            ActivePosition += TempBuffer.Position;
                            ActiveRate += TempBuffer."Daily Rate";
                        end;
            until TempBuffer.Next() = 0;
        if ActiveRate <= 0 then
            exit(Low);
        Level := (Quantity - Fixed + ActivePosition) / ActiveRate;
        if (Level < Low) or (TotalAtLevel(TempBuffer, Level) > Quantity) then
            exit(Low);
        exit(Level);
    end;

    local procedure TotalAtLevel(var TempBuffer: Record "DP Allocation Buffer KBS" temporary; Level: Decimal) Total: Decimal
    begin
        if TempBuffer.FindSet() then
            repeat
                if TempBuffer.Need > 0 then
                    Total += AllocationAtLevel(TempBuffer, Level);
            until TempBuffer.Next() = 0;
    end;

    local procedure AllocationAtLevel(TempBuffer: Record "DP Allocation Buffer KBS" temporary; Level: Decimal): Decimal
    begin
        exit(Minimum(TempBuffer.Need, Maximum(0, Level * TempBuffer."Daily Rate" - TempBuffer.Position)));
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
        PositiveRateErr: Label 'Daglig forbruk må være større enn null for lokasjon %1 når butikken har behov.', Comment = '%1 = Location code';
}
