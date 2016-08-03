import matplotlib as mpl
from matplotlib import pyplot as plt, ticker as tkr

mpl.use('Agg')


class ListNotEqualError(Exception):
    def __init__(self, message, errors):
        super(ListNotEqualError, self).__init__(message)


class PlotPoints(object):
    def cleanse_string(self, s):
        return str(s).replace('"', '').replace("'", "")

    def plot_points(self, x_list, y_list, x_label, y_label, title, filename):
        """ Plot a graph between two lists
            Note:
                x_list and y_list should always be a lists of integers.
                the length of the two lists should be equal.
            Args:
                x_list(list): list of elements to be plotted on x axis.
                y_list(list): list of elements to be plotted on y axis.
                x_label(str): label of x axis.
                y_label(str): label of y axis.
                title(str): title of the plot.
                filename(str): filename to save the graph generated.
        """
        x_label = self.cleanse_string(x_label)
        y_label = self.cleanse_string(y_label)
        title = self.cleanse_string(title)
        filename = self.cleanse_string(filename)

        if len(x_list) != len(y_list):
            raise ListNotEqualError('length of lists not equal')

        fig, ax = plt.subplots()

        ax.plot(x_list, y_list, 'c-')
        ax.grid(color='grey')
        ax.patch.set_facecolor('black')

        axes = plt.gca()
        axes.get_yaxis().get_major_formatter().set_scientific(False)
        axes.get_yaxis().get_major_formatter().set_useOffset(False)

        ax.set_xlabel(x_label)
        ax.set_ylabel(y_label)
        ax.set_title(title)

        if isinstance(x_list[0], int):
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             int(x)))
        else:
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             float(x)))

        if isinstance(y_list[0], int):
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             int(x)))
        else:
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             float(x)))
        plt.savefig(filename, bbox_inches='tight')
