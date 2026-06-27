from utils.printing import Printing
from sklearn.metrics import *

class RegressionPerformance(Printing): 
    def __init__(
        self,

        # Context Object
        context = None,

        # Dataset
        y = None, 
        y_hat = None,
        y_proba = None
    ):
        # Context 
        self.split_run = context

        # Score Containers 
        self.scores = {}
    
        # Dataset 
        self.y = y 
        self.y_hat = y_hat 
        self.y_proba = y_proba

    def compute(self): 
        self.print(f"> Computing performance.")
        self.compute_rmse_score() 
        self.compute_r2_score() 
        self.compute_mae_score() 
        self.compute_mape_score() 
        self.compute_mse_score() 
        self.compute_rmsle_score() 
        self.compute_adjusted_r2_score() 
        self.compute_residuals() 
        self.generate_error_plot()
    
    def compute_rmse_score(self): 
        self.print(f"> Computing RMSE Score")
        score = root_mean_squared_error(self.y, self.y_hat)
        self.scores["rmse"] = score
        self.print(f"\t:: Result: {score}")
    
    def compute_r2_score(self): 
        self.print(f"> Computing R2 Score.")
        score = r2_score(self.y, self.y_hat)
        self.scores["r2"] = score
        self.print(f"\t:: Result: {score}")
        
    def compute_mae_score(self): 
        self.print(f"> Computing MAE Score.") 
        score = mean_absolute_error(self.y, self.y_hat)
        self.scores["mae"] = score
        self.print(f"\t:: Result: {score}")

    def compute_mape_score(self):
        self.print(f"> Computing MAPE Score.")
        score = mean_absolute_percentage_error(self.y, self.y_hat)
        self.scores["mae"] = score
        self.print(f"\t:: Result: {score}")

    def compute_mse_score(self): 
        self.print(f"> Computing MSE Score.")
        score = mean_squared_error(self.y, self.y_hat)
        self.scores["mae"] = score
        self.print(f"\t:: Result: {score}")

    def compute_rmsle_score(self): 
        try:
            self.print(f"> Computing RMSLE Score.")
            score = root_mean_squared_log_error(self.y, self.y_hat)
            self.scores["mae"] = score
            self.print(f"\t:: Result: {score}")
        except: 
            self.print(f"> RMSLE failed or not applicable, skipping...")

    def compute_adjusted_r2_score(self):
        self.print(f"> Computing Adjusted R2 Score.")

        n = len(self.y)
        p = self.split_run.experiment.class_count

        if p is None or n <= p + 1:
            score = float("nan")
        else:
            r2 = r2_score(self.y, self.y_hat)
            score = 1 - (1 - r2) * (n - 1) / (n - p - 1)

        self.scores["adjusted_r2"] = score
        self.print(f"\t:: Result: {score}")

    def compute_residuals(self):
        self.print(f"> Computing Residuals.")

    def generate_error_plot(self): 
        self.print(f"> Generating Error Plot")

    