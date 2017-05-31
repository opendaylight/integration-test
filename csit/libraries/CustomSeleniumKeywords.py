from robot.libraries.BuiltIn import BuiltIn


def get_webdriver_instance():
    se2lib = BuiltIn().get_library_instance('Selenium2Library')
    return se2lib._current_browser()


def get_browser_console_content(driver):
    console_content = driver.get_log('browser')
    return console_content
