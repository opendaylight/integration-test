*** Settings ***
Documentation     A resource file containing all global Yangman GUI variables
...               to help Yangman GUI and functional testing.
Resource          Variables.robot

*** Variables ***
${YANGMAN_LOGO}    //img[contains(@ng-src, "assets/images/logo_yangman.png") and contains(@id, "page_logo")]
${TOGGLE_MENU_BUTTON}    //a[@id="toggleMenu"]
${LOGOUT_BUTTON}    //a[@id="logout-button"]
# Left Panel
${MODULES_TAB_NAME}    Modules
${HISTORY_TAB_NAME}    History
${COLLECTIONS_TAB_NAME}    Collections
${LEFT_TAB_AREA}    //md-tab-content[@id="tab-content-0"]
${MODULES_TAB_SELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${MODULES_TAB_NAME}")]
${MODULES_TAB_UNSELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${MODULES_TAB_NAME}")]
${HISTORY_TAB_SELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${HISTORY_TAB_NAME}")]
${HISTORY_TAB_UNSELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${HISTORY_TAB_NAME}")]
${COLLECTIONS_TAB_SELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${COLLECTIONS_TAB_NAME}")]
${COLLECTIONS_TAB_UNSELECTED}    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${COLLECTIONS_TAB_NAME}")]
${MODULES_WERE_LOADED_ALERT}    //span[contains(text(), "Modules were loaded.")]
${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}    //md-icon[@class="arrow-switcher material-icons" and @id="toggle-module-detail"]
${TOGGLE_MODULE_DETAIL_BUTTON_RIGHT}    //md-icon[@class="arrow-switcher material-icons arrow-switcher__left"" and @id="toggle-module-detail"]
# Modules Tab Left Panel
${MODULE_TAB_CONTENT}    //*[@id="tab-content-2"]
${MODULE_SEARCH_INPUT}    //input[@id="search-modules"]
${MODULE_ID_LABEL}    module_
${MODULE_LIST_ITEM}    ${MODULE_TAB_CONTENT}//md-list-item[contains(@id, "${MODULE_ID_LABEL}")]//div[@class="pointer title layout-align-center-center layout-row"]
${MODULE_LIST_ITEM_COLLAPSED}    ${MODULE_LIST_ITEM}//following-sibling::md-list[@aria-hidden="true"]
${MODULE_LIST_ITEM_EXPANDED}    ${MODULE_LIST_ITEM}//following-sibling::md-list[@aria-hidden="false"]
${MODULE_LIST_MODULE_NAME_XPATH}    ${MODULE_LIST_ITEM}//p[@class="top-element flex"]
${OPERATIONS_LABEL}    operations
${OPERATIONAL_LABEL}    operational
${CONFIG_LABEL}    config
${TESTING_MODULE_NAME}    ${EMPTY}
${TESTING_MODULE_XPATH}    ${MODULE_TAB_CONTENT}//p[contains(., "${TESTING_MODULE_NAME}")]//ancestor::md-list-item[contains(@id, "${MODULE_ID_LABEL}")]
# Module Detail
${MODULE_DETAIL_CONTENT}    //*[@id="tab-content-1"]
${MODULE_DETAIL_MODULE_NAME_LABEL}    ${MODULE_DETAIL_CONTENT}//h4
${MODULE_DETAIL_OPERATIONS_TAB_SELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${OPERATIONS_LABEL}")]
${MODULE_DETAIL_OPERATIONS_TAB_DESELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${OPERATIONS_LABEL}")]
${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${OPERATIONAL_LABEL}")]
${MODULE_DETAIL_OPERATIONAL_TAB_DESELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${OPERATIONAL_LABEL}")]
${MODULE_DETAIL_CONFIG_TAB_SELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${CONFIG_LABEL}")]
${MODULE_DETAIL_CONFIG_TAB_DESELECTED}    ${MODULE_DETAIL_CONTENT}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${CONFIG_LABEL}")]
${MODULE_DETAIL_TAB_CONTENT_LABEL}    tab-content-
${MODULE_DETAIL_ACTIVE_TAB_CONTENT}    ${MODULE_DETAIL_CONTENT}//md-tab-content[contains(@class, "md-active")]
${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-icon[contains(., "add")]
${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-list-item//md-icon[contains(., "remove")]
${BRANCH_LABEL}    ${EMPTY}
${NETWORK_TOPOLOGY_LABEL}    network-topology
${TOPOLOGY_TOPOLOGY_ID_LABEL}    topology {topology-id}
${NODE_NODE_ID_LABEL}    node {node-id}
${LINK_LINK_ID_LABEL}    link {link-id}
${BRANCH_ID_LABEL}    branch-
${MODULE_DETAIL_BRANCH}    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-list-item[contains(@id, "${BRANCH_ID_LABEL}")]
${MODULE_DETAIL_BRANCH_BUTTON}    ${MODULE_DETAIL_BRANCH}/button
${MODULE_DETAIL_BRANCH_LABEL}    ${MODULE_DETAIL_BRANCH}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${BRANCH_LABEL}")]
#History Tab Left Panel
${HISTORY_SEARCH_INPUT}    //input[@id="search-history"]
${SAVE_HISTORY_REQUEST_TO_COLLECTION_BUTTON}    //button[@id="history-save-requests"]
${DELETE_HISTORY_REQUEST_MENU}    //button[@id="history-delete-menu"]
${DELETE_SELECTED_HISTORY_REQUEST_BUTTON}    //button[@id="history-delete-selected"]
${DELETE_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-delete-all"]
${SELECT_HISTORY_REQUEST_MENU}    //button[@id="history-select-menu"]
${SELECT_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-select-all"]
${DESELECT_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-deselect-all"]
#Collections Tab Left Panel
${COLLECTIONS_SEARCH_INPUT}    //input[@id="search-collections"]
${SAVE_SELECTED_REQUEST_TO_COLLECTION_BUTTON}    //button[@id="collections-save-selected"]
${IMPORT_COLLECTION_BUTTON}    //button[@id="importCollection"]
${DELETE_HISTORY_REQUEST_MENU}    //button[@id="history-delete-menu"]
${DELETE_SELECTED_HISTORY_REQUEST_BUTTON}    //button[@id="history-delete-selected"]
${DELETE_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-delete-all"]
${SELECT_HISTORY_REQUEST_MENU}    //button[@id="history-select-menu"]
${SELECT_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-select-all"]
${DESELECT_ALL_HISTORY_REQUESTS_BUTTON}    //button[@id="history-deselect-all"]
#Right Panel Header
${OPERATION_NAME}    EMPTY
${OPERATION_SELECT_INPUT}    //md-select[@id="request-selected-operation"]
${OPERATION_SELECT_INPUT_CLICKABLE}    ${OPERATION_SELECT_INPUT}//parent::md-input-container
${SELECT_BACKDROP}    //md-backdrop[@class="md-select-backdrop md-click-catcher ng-scope"]
${OPERATION_SELECT_MENU_EXPANDED}    //div[contains(@aria-hidden, "false") and contains(@id,"select_container_10")]
${GET_OPTION}     //*[@id="select_option_12"]
${POST_OPTION}    //*[@id="select_option_13"]
${PUT_OPTION}     //*[@id="select_option_14"]
${DELETE_OPTION}    //*[@id="select_option_15"]
${SELECTED_OPERATION_XPATH}    ${OPERATION_SELECT_INPUT}//span/div[contains(text(), "${OPERATION_NAME}")]
${REQUEST_URL_INPUT}    //*[@id="request-url"]
${SEND_BUTTON}    //*[@id="send-request"]
${SAVE_BUTTON}    //*[@id="save-request"]
${PARAMETERS_BUTTON}    //*[@id="show-parameters"]
${FORM_RADIOBUTTON_SELECTED}    //md-radio-button[contains(@id, "shown-data-type-form") and contains(@aria-checked, "true")]
${FORM_RADIOBUTTON_UNSELECTED}    //md-radio-button[contains(@id, "shown-data-type-form") and contains(@aria-checked, "false")]
${JSON_RADIOBUTTON_SELECTED}    //md-radio-button[contains(@id, "shown-data-type-json") and contains(@aria-checked, "true")]
${JSON_RADIOBUTTON_UNSELECTED}    //md-radio-button[contains(@id, "shown-data-type-json") and contains(@aria-checked, "false")]
${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_SELECTED}    //span[contains(text(), "Fill form with received data after execution")]//ancestor::md-checkbox[@aria-checked="true"]
${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_UNSELECTED}    //span[contains(text(), "Fill form with received data after execution")]//ancestor::md-checkbox[@aria-checked="false"]
${SHOW_SENT_DATA_CHECKBOX_SELECTED}    //md-checkbox[@id="show-sent-data-checkbox" and @aria-checked="true"]
${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}    //md-checkbox[@id="show-sent-data-checkbox" and @aria-checked="false"]
${SHOW_RECEIVED_DATA_CHECKBOX_SELECTED}    //md-checkbox[@id="show-received-data-checkbox" and @aria-checked="true"]
${SHOW_RECEIVED_DATA_CHECKBOX_UNSELECTED}    //md-checkbox[@id="show-received-data-checkbox" and @aria-checked="false"]
${MILLISECONDS_LABEL}    ms
${STATUS_LABEL}    //span[contains(text(), "Status:")]
${STATUS_VALUE}    //span[@id="info-request-status"]
${THREE_DOTS_DEFAULT_STATUS_AND_TIME}    ...
${20X_REQUEST_CODE_REGEX}    .*([2][0][0-6]).*
${40X_REQUEST_CODE_REGEX}    .*([4][0-1][0-9]).*
${20X_OR_40X_REQUEST_CODE_REGEX}    .*([24][0-1][0-9]).*
${TIME_LABEL}     //span[contains(text(), "Time:")]
${TIME_VALUE}     //span[@id="info-request-execution-time"]
${API_PATH}       //section[contains(@class, "yangmanModule__right-panel__header")]//section[@class="layout-wrap layout-row flex"]
${HEADER_LINEAR_PROGRESSION_BAR_HIDDEN}    //section[contains(@class, "yangmanModule__right-panel__header")]/md-progress-linear[@aria-hidden="true"]
#Right Panel Json Content
${SENT_DATA_CODE_MIRROR_DISPLAYED}    //div[@id="sentData" and @aria-hidden="false"]
${SENT_DATA_CODE_MIRROR_CODE}    ${SENT_DATA_CODE_MIRROR_DISPLAYED}//div[@class="CodeMirror-code"]
${SENT_DATA_LABEL}    ${SENT_DATA_CODE_MIRROR_DISPLAYED}//h5[contains(text(), Sent data)]
${SENT_DATA_ENLARGE_FONT_SIZE_BUTTON}    ${SENT_DATA_CODE_MIRROR_DISPLAYED}//button[contains(@aria-label, arrow_drop_up)]
${SENT_DATA_REDUCE_FONT_SIZE_BUTTON}    ${SENT_DATA_CODE_MIRROR_DISPLAYED}//button[contains(@aria-label, arrow_drop_down)]
${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}    //div[@id="ReceiveData" and @aria-hidden="false"]
${RECEIVED_DATA_CODE_MIRROR_CODE}    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}//div[@class="CodeMirror-code"]
${RECEIVED_DATA_LABEL}    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}//h5[contains(text(), Received data)]
${RECEIVED_DATA_ENLARGE_FONT_SIZE_BUTTON}    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}//button[contains(@aria-label, arrow_drop_up)]
${RECEIVED_DATA_REDUCE_FONT_SIZE_BUTTON}    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}//button[contains(@aria-label, arrow_drop_down)]
${JSON_ERROR_MESSAGE_INPUT_IS_MISSING}    Error parsing input: Input is missing some of the keys of
${JSON_ERROR_MESSAGE_CONTENT_DOES_NOT_EXIST}    Request could not be completed because the relevant data model content does not exist
${JSON_ERROR_MESSAGE_DATA_DOES_NOT_EXIST_FOR_PATH}    Data does not exist for path
${JSON_ERROR_MESSAGE_INPUT_IS_REQUIRED}    Input is required.
# Right Panel Form Content
${TOPOLOGY_ID_LABEL}    topology-id
${FORM_ERROR_MESSAGE}    ${EMPTY}
${FORM_CONTENT}    //section[contains(@class, "yangmanModule__right-panel__form bottom-content ng-scope") and contains(@aria-hidden, "false")]
${ERROR_MESSAGE_IDENTIFIERS_IN_PATH_REQUIRED}    Identifiers in path are required. Please fill empty identifiers for successful request execution.
${FORM_ERROR_MESSAGE_XPATH}    //p[contains(@id, "form-error-message") and contains (text(), "${FORM_ERROR_MESSAGE}")]
${FORM_TOP_ELEMENT_CONTAINER}    ${FORM_CONTENT}//div[contains(@class, "yangmanModule__right-panel__form__element-container ng-scope")]
${FORM_TOP_ELEMENT_POINTER}    ${FORM_TOP_ELEMENT_CONTAINER}//p[contains(@class, "top-element pointer")]
${FORM_TOP_ELEMENT_LABEL_XPATH}    ${FORM_TOP_ELEMENT_POINTER}//span[contains(@class, "ng-binding ng-scope")]
${FORM_TOP_ELEMENT_YANGMENU}    ${FORM_TOP_ELEMENT_CONTAINER}//yang-form-menu
${FORM_TOP_ELEMENT_LIST_ITEM_ROW}    ${FORM_TOP_ELEMENT_CONTAINER}//section[@class="yangmanModule__right-panel__form__list__paginator ng-scope layout-column flex"]
${FORM_TOP_ELEMENT_LIST_ITEM}    ${FORM_TOP_ELEMENT_LIST_ITEM_ROW}//md-tab-item[contains(@class, "md-tab ng-scope ng-isolate-scope md-ink-ripple")]
${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}    ${FORM_TOP_ELEMENT_LIST_ITEM}/span
${YANGMENU_ADD_LIST_ITEM_BUTTON}    ${FORM_CONTENT}//yang-form-menu//button[@ng-click="addListItemFunc(); closeMenu();"]
${YANGMENU_SHOW_ALL_LIST_ITEMS}    ${FORM_CONTENT}//yang-form-menu//button[@ng-click="switchSection('items'); setItemList();"]
${YANGMENU_AUGMENTATIONS_BUTTON}    ${FORM_CONTENT}//yang-form-menu//button[ng-click="switchSection('augmentations')"]
${FORM_SHOW_PREVIOUS_ITEM_ARROW}    //md-prev-button[@aria-label="Previous Page"]
${FORM_SHOW_NEXT_ITEM_ARROW}    //md-next-button[@aria-label="Next Page"]
