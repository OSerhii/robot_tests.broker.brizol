*** Settings ***
Library  Selenium2Screenshots
Library  String
Library  DateTime
Library  brizol_service.py

*** Variables ***

*** Keywords ***

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   adapt_procuringEntity   ${role_name}   ${tender_data}
  [return]  ${tender_data}

Підготувати клієнт для користувача
  [Arguments]  ${username}
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${username}
  Set Window Size  @{USERS.users['${username}'].size}
  Set Window Position  @{USERS.users['${username}'].position}
  Run Keyword If  '${username}' != 'brizol_Viewer_auction'  Login  ${username}

Login
  [Arguments]  ${username}
  Wait Until Page Contains Element  id=loginform-username  10
  Input text  id=loginform-username  ${USERS.users['${username}'].login}
  Input text  id=loginform-password  ${USERS.users['${username}'].password}
  Click Element  name=login-button

###############################################################################################################
######################################    СТВОРЕННЯ ТЕНДЕРУ    ################################################
###############################################################################################################

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${items}=  Get From Dictionary  ${tender_data.data}  items
  Switch Browser  ${username}
  Wait Until Page Contains Element  xpath=//a[@href="https://eauction.brizol.net/tenders"]  10
  Click Element  xpath=//a[@href="https://eauction.brizol.net/tenders"]
  Click Element  xpath=//a[@href="https://eauction.brizol.net/tenders/index"]
  Click Element  xpath=//a[contains(@href,"https://eauction.brizol.net/buyer/tender/create")]
  Conv And Select From List By Value  name=Tender[value][valueAddedTaxIncluded]  ${tender_data.data.value.valueAddedTaxIncluded}
  ConvToStr And Input Text  name=Tender[value][amount]  ${tender_data.data.value.amount}
  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${tender_data.data.minimalStep.amount}
  ConvToStr And Input Text  name=Tender[guarantee][amount]  ${tender_data.data.guarantee.amount}
  Input text  name=Tender[title]  ${tender_data.data.title}
  Input text  name=Tender[description]  ${tender_data.data.description}
  Input Date  name=Tender[auctionPeriod][startDate]  ${tender_data.data.auctionPeriod.startDate}
  Додати предмет  ${items[0]}  0
  Click Element  xpath= //button[@class="btn btn-default btn_submit_form"]
  Wait Until Page Contains Element  xpath=//b[@tid="tenderID"]  10
  ${tender_uaid}=  Get Text  xpath=//b[@tid="tenderID"]
  [return]  ${tender_uaid}

Додати предмет
  [Arguments]  ${item}  ${index}
  ${index}=  Convert To Integer  ${index}
  Input text  name=Tender[items][${index}][description]  ${item.description}
  Input text  name=Tender[items][${index}][quantity]  ${item.quantity}
  Select From List By Value  name=Tender[items][${index}][unit][code]  ${item.unit.code}
  Click Element  name=Tender[items][${index}][classification][description]
  Wait Until Element Is Visible  id=search
  Input text  id=search  ${item.classification.description}
  Wait Until Page Contains  ${item.classification.description}
  Click Element  xpath=//span[contains(text(),'${item.classification.description}')]
  Click Element  id=btn-ok
  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Input text  name=Tender[items][${index}][address][countryName]  ${item.deliveryAddress.countryName}
  Input text  name=Tender[items][${index}][address][region]  ${item.deliveryAddress.region}
  Input text  name=Tender[items][${index}][address][locality]  ${item.deliveryAddress.locality}
  Input text  name=Tender[items][${index}][address][streetAddress]  ${item.deliveryAddress.streetAddress}
  Input text  name=Tender[items][${index}][address][postalCode]  ${item.deliveryAddress.postalCode}
  Select From List By Value  name=Tender[procuringEntity][contactPoint][fio]  24

Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Switch Browser  ${username}
  Go to  ${USERS.users['${username}'].homepage}
  Click Element  xpath=//div[@tid="tender_dropdown"]/button
  Click Element  xpath=//a[@href="/buyer/tenders"]
  Click Element  xpath=//div[@id="w1"]/div[2]//a[@class="btn btn-success"]
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Choose File  name=FileUpload[file]  ${filepath}
  Click Button  xpath=//button[@class="btn btn-default btn_submit_form"]

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tenderID}
  Switch browser  ${username}
  Go To  https://eauction.brizol.net/tenders/
  Input text  name=TendersSearch[tender_cbd_id]  ${tenderID}
  Click Element  xpath=//button[@class="btn btn-success top-buffer margin23"]
  Wait Until Keyword Succeeds  30x  400ms  Перейти на сторінку з інформацією про тендер  ${tenderID}

Перейти на сторінку з інформацією про тендер
  [Arguments]  ${tenderID}
  Wait Until Element Contains  xpath=//div[@class="summary"]/b[2]  1
  Click Element  xpath=//h3[contains(text(),'${tenderID}')]/ancestor::div[@class="row"]/descendant::a[contains(@href,'/tender/view/')]
  Wait Until Element Is Visible  xpath=//*[@tid="tenderID"]

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tenderID}
  Reload Page

Внести зміни в тендер
  [Arguments]  ${username}  ${tenderID}  ${field_name}  ${field_value}
  brizol.Пошук тендера по ідентифікатору  ${username}  ${tenderID}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Input text  name=Tender[${field_name}]  ${field_value}
  Click Element  xpath=//button[@class="btn btn-default btn_submit_form"]
  Wait Until Page Contains  ${field_value}  30

###############################################################################################################
############################################    ПИТАННЯ    ####################################################
###############################################################################################################

Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  brizol.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, '/questions')]
  Input Text  name=Question[title]  ${question.data.title}
  Input Text  name=Question[description]  ${question.data.description}
  Click Element  name=question_submit
  Wait Until Page Contains  ${question.data.description}

Відповісти на питання
  [Arguments]  ${username}  ${tenderID}  ${question}  ${answer_data}  ${question_id}
  brizol.Пошук тендера по ідентифікатору  ${username}  ${tenderID}
  Click Element  xpath=//a[contains(@href, '/questions')]
  Wait Until Element Is Visible  name=Tender[0][answer]
  Input text  name=Tender[0][answer]  ${answer_data.data.answer}
  Click Element  name=answer_question_submit
  Wait Until Page Contains  ${answer_data.data.answer}  30

###############################################################################################################
###################################    ВІДОБРАЖЕННЯ ІНФОРМАЦІЇ    #############################################
###############################################################################################################

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  Run Keyword If  '${field_name}' == 'status'  Click Element   xpath=//a[text()='Інформація про закупівлю']
  ${value}=  Run Keyword If
  #...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на brizol
  #...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//*[@tid="items.quantity"]
  #...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на brizol
  #...  ELSE IF  'items' in '${field_name}'  Get Text  xpath=//*[@tid="${field_name.replace('[0]', '')}"]
  #...  ELSE IF  'questions' in '${field_name}'  brizol.Отримати інформацію із запитання  ${field_name}
  ...  'value' in '${field_name}'  Get Text  xpath=//*[@tid="value.amount"]
  ...  ELSE  Get Text  xpath=//*[@tid="${field_name.replace('auction', 'tender')}"]
  ${value}=  adapt_view_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на brizol
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на brizol
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.quantity']
  ...  ELSE  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію із запитання
  [Arguments]  ${field_name}
  Click Element  xpath=//a[contains(@href, '/questions')]
  ${value}=  Get Text  xpath=//*[@tid="${field_name.replace('[0]', '')}"]
  [return]  ${value}

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${bid_value}=   Get Text   xpath=//div[contains(text(), 'Ваша ставка')]
  ${bid_value}=   Convert To Number   ${bid_value.split(' ')[-2]}
  [return]  ${bid_value}

###############################################################################################################
#######################################    ПОДАННЯ ПРОПОЗИЦІЙ    ##############################################
###############################################################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${file_path}=  get_upload_file_path
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${bid.data.value.amount}
  Choose File  name=FileUpload[file]  ${file_path}
  Select From List By Value  name=documents[0][documentType]  financialLicense
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]

Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Execute Javascript  window.confirm = function(msg) { return true; }
  Click Element  xpath=//button[@name="delete_bids"]

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  ${file_path}=  get_upload_file_path
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  brizol.Скасувати цінову пропозицію  ${username}  ${tender_uaid}  ${EMPTY}
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${fieldvalue}
  Choose File  name=FileUpload[file]  ${file_path}
  Select From List By Value  name=documents[0][documentType]  financialLicense
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  Capture Page Screenshot

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Capture Page Screenshot
  ${value}=  brizol.Отримати інформацію із пропозиції  ${username}  ${tender_uaid}  ${EMPTY}
  brizol.Скасувати цінову пропозицію  ${username}  ${tender_uaid}  ${EMPTY}
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${value}
  Choose File  name=FileUpload[file]  ${path}
  Select From List By Value  name=documents[0][documentType]  financialLicense
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]

Змінити документ в ставці
  [Arguments]  ${username}  ${path}  ${bidid}  ${docid}
  Wait Until Keyword Succeeds   30 x   10 s   Дочекатися вивантаження файлу до ЦБД
  Execute Javascript  window.confirm = function(msg) { return true; }
  Choose File  xpath=//div[contains(text(), 'Замiнити')]/form/input  ${path}
  Click Element  xpath=//button[contains(text(), 'Вiдправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]

###############################################################################################################
##############################################    АУКЦІОН    ##################################################
###############################################################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}  Get Element Attribute  xpath=//a[contains(text(), 'Аукцiон')]@href
  [return]  ${auction_url}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  brizol.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}  Get Element Attribute  xpath=//a[contains(text(), 'Аукцiон')]@href
  [return]  ${auction_url}

###############################################################################################################

ConvToStr And Input Text
  [Arguments]  ${elem_locator}  ${smth_to_input}
  ${smth_to_input}=  Convert To String  ${smth_to_input}
  Input Text  ${elem_locator}  ${smth_to_input}

Conv And Select From List By Value
  [Arguments]  ${elem_locator}  ${smth_to_select}
  ${smth_to_select}=  Convert To String  ${smth_to_select}
  ${smth_to_select}=  convert_string_from_dict_brizol  ${smth_to_select}
  Select From List By Value  ${elem_locator}  ${smth_to_select}

Input Date
  [Arguments]  ${elem_locator}  ${date}
  ${date}=  convert_datetime_to_brizol_format  ${date}
  Input Text  ${elem_locator}  ${date}

Дочекатися вивантаження файлу до ЦБД
  Reload Page
  Wait Until Element Is Visible   xpath=//div[contains(text(), 'Замiнити')]