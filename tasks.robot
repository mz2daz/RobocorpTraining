*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot website
    ${orders}=    Get Excel file
    FOR    ${orders}    IN    @{orders}
        ${ReceiptsFolder}=    Input data    ${orders}
    END
    Archive receipts    ${ReceiptsFolder}
    [Teardown]    Close browser


*** Keywords ***
Open robot website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${file}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${file}

Close pop up
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK

Click Order
    Click Button    order
    Wait Until Page Does Not Contain Element    order

#Close pop up/Fill Form/Create PDFs

Input data
    [Arguments]    ${orders}
    Close pop up
    Wait Until Page Contains Element    id:head
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    1 min    1 sec    Click Order
    Wait Until Page Contains Element    receipt
    ${Filepath}=    Save as PDF    ${orders}[Order number]
    ${ScreenshotPath}=    Take a screenshot    ${orders}[Order number]
    Emebed screenshot on receipt    ${ScreenshotPath}    ${Filepath}
    Remove File    ${ScreenshotPath}
    Wait Until Page Contains Element    order-another
    Click Button    order-another
    RETURN    ${OUTPUT_DIR}${/}ReceiptsFolder

#Get outerHTML for receipts then create a PDF

Save as PDF
    [Arguments]    ${orderNumber}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}ReceiptsFolder${/}OrderReceiptNum${orderNumber}.pdf
    RETURN    ${OUTPUT_DIR}${/}ReceiptsFolder${/}OrderReceiptNum${orderNumber}.pdf

#Take screenshot of robot

Take a screenshot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robotScreenshots${/}${order}.png
    RETURN    ${OUTPUT_DIR}${/}robotScreenshots${/}${order}.png

#Open Pdf / embed robot screenshot / close Pdf to all PDFs

Emebed screenshot on receipt
    [Arguments]    ${screenshot}    ${Receipt}
    Open Pdf    ${Receipt}
    Add Watermark Image To Pdf    ${screenshot}    ${Receipt}
    Close Pdf    ${Receipt}

#Archive PDFs then delete all PDFs

Archive receipts
    [Arguments]    ${ReceiptsFolder}
    Archive Folder With Zip    ${ReceiptsFolder}    ${OUTPUT_DIR}${/}RECEIPTS.zip
    Empty Directory    ${OUTPUT_DIR}${/}ReceiptsFolder
    Remove Directory    ${OUTPUT_DIR}${/}ReceiptsFolder
    Remove Directory    ${OUTPUT_DIR}${/}robotScreenshots

Close browser
    Close All Browsers
