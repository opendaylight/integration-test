"""
YangUI library for additional keywords needed for testing YangUI module.
Author: Dasa Simkova
"""

def Remove_Leading_And_Trailing_Spaces(string):
    """Removes leading and trailing spaces from a chosen string."""
    resulting_string = string.strip('\r\n')
    return resulting_string
    
    


#import time


#def highlight(element):
#    """Highlights (blinks) a Selenium Webdriver element"""
#    def apply_style(s):
#        driver.execute_script("arguments[0].setAttribute('style', arguments[1]);",
#                              element, s)
#    original_style = element.get_attribute('style')
#    apply_style("background: yellow; border: 2px solid red;")
#    time.sleep(.3)
#    apply_style(original_style)
