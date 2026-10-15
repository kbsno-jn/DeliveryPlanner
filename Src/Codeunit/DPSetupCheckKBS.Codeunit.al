namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;

codeunit 78909 "DP Setup Check KBS"
{
    var
        HubIsStoreTxt: Label 'Hovedlageret er aktivert som butikk.';
        StoreInTransitTxt: Label 'Butikken er en transittlokasjon.';
        MissingCategoryTxt: Label 'Butikken mangler butikkategori.';
        UnknownCategoryTxt: Label 'Butikkategori %1 finnes ikke.', Comment = '%1 = category code';
        InvalidCoverageTxt: Label 'Butikkategori %1 må ha minst én dekningsdag.', Comment = '%1 = category code';
        InvalidWeightTxt: Label 'Butikkategori %1 må ha fordelingsvekt større enn null.', Comment = '%1 = category code';
        MissingRouteTxt: Label 'Overføringsrute fra %1 til %2 mangler.', Comment = '%1 = hub, %2 = store';
        MissingTransitTxt: Label 'Overføringsruten fra %1 til %2 mangler gyldig transittlokasjon.', Comment = '%1 = hub, %2 = store';
        NotInventoryItemTxt: Label 'Varen er ikke en lagervare.';
        UnknownVariantTxt: Label 'Varianten %1 finnes ikke.', Comment = '%1 = variant code';
        NotTransferTxt: Label 'Etterforsyningssystem må være Overføring.';
        WrongSourceTxt: Label 'Overfør fra-kode må være hovedlageret %1.', Comment = '%1 = hub';
        MissingMaximumTxt: Label 'Makslager må være større enn null.';
        InvalidSafetyStockTxt: Label 'Sikkerhetslager må være mellom null og makslager.';
        InvalidOrderMultipleTxt: Label 'Ordremultippel kan ikke være negativ.';
        OtherWorksheetTxt: Label 'Har forslag i kladden %1/%2. Behandle disse før varen kan forsynes.', Comment = '%1 = template, %2 = batch';

    /// <summary>
    /// Returns why the store cannot be supplied, or an empty text when the store setup is valid.
    /// </summary>
    procedure GetStoreProblem(Setup: Record "DP Setup KBS"; Store: Record Location): Text[250]
    var
        Category: Record "DP Store Category KBS";
        Route: Record "Transfer Route";
        Transit: Record Location;
    begin
        if Store.Code = Setup."Hub Location Code" then
            exit(HubIsStoreTxt);
        if Store."Use As In-Transit" then
            exit(StoreInTransitTxt);
        if Store."DP Category Code KBS" = '' then
            exit(MissingCategoryTxt);
        if not Category.Get(Store."DP Category Code KBS") then
            exit(StrSubstNo(UnknownCategoryTxt, Store."DP Category Code KBS"));
        if Category."Coverage Days" < 1 then
            exit(StrSubstNo(InvalidCoverageTxt, Category.Code));
        if Category."Allocation Weight" <= 0 then
            exit(StrSubstNo(InvalidWeightTxt, Category.Code));
        if not Route.Get(Setup."Hub Location Code", Store.Code) then
            exit(StrSubstNo(MissingRouteTxt, Setup."Hub Location Code", Store.Code));
        if Route."In-Transit Code" = '' then
            exit(StrSubstNo(MissingTransitTxt, Setup."Hub Location Code", Store.Code));
        if not Transit.Get(Route."In-Transit Code") then
            exit(StrSubstNo(MissingTransitTxt, Setup."Hub Location Code", Store.Code));
        if not Transit."Use As In-Transit" then
            exit(StrSubstNo(MissingTransitTxt, Setup."Hub Location Code", Store.Code));
        exit('');
    end;

    /// <summary>
    /// Returns why the stockkeeping unit cannot be supplied, or an empty text when it is valid.
    /// </summary>
    procedure GetSKUProblem(Setup: Record "DP Setup KBS"; SKU: Record "Stockkeeping Unit"): Text[250]
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ReqLine: Record "Requisition Line";
    begin
        if not Item.Get(SKU."Item No.") then
            exit(NotInventoryItemTxt);
        if Item.Type <> Item.Type::Inventory then
            exit(NotInventoryItemTxt);
        if SKU."Variant Code" <> '' then
            if not ItemVariant.Get(SKU."Item No.", SKU."Variant Code") then
                exit(StrSubstNo(UnknownVariantTxt, SKU."Variant Code"));
        if SKU."Replenishment System" <> SKU."Replenishment System"::Transfer then
            exit(NotTransferTxt);
        if SKU."Transfer-from Code" <> Setup."Hub Location Code" then
            exit(StrSubstNo(WrongSourceTxt, Setup."Hub Location Code"));
        if SKU."Maximum Inventory" <= 0 then
            exit(MissingMaximumTxt);
        if (SKU."Safety Stock Quantity" < 0) or (SKU."Safety Stock Quantity" > SKU."Maximum Inventory") then
            exit(InvalidSafetyStockTxt);
        if SKU."Order Multiple" < 0 then
            exit(InvalidOrderMultipleTxt);
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", SKU."Item No.");
        ReqLine.SetRange("Variant Code", SKU."Variant Code");
        ReqLine.SetRange("Location Code", SKU."Location Code");
        if ReqLine.FindSet() then
            repeat
                if (ReqLine."Worksheet Template Name" <> Setup."Worksheet Template Name") or
                   (ReqLine."Journal Batch Name" <> Setup."Worksheet Batch Name")
                then
                    exit(StrSubstNo(OtherWorksheetTxt, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name"));
            until ReqLine.Next() = 0;
        exit('');
    end;
}
