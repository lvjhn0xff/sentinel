from core.experiment.cv_experiment import CrossValidationExperiment 
from sklearn.preprocessing import StandardScaler

from core.datasets.clf_2d import load_clf_2d
from core.datasets.reg_2d import load_reg_2d

from imblearn.pipeline import Pipeline
from imblearn.over_sampling import SMOTE

from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from xgboost import XGBClassifier
from sklearn.neighbors import KNeighborsClassifier, RadiusNeighborsClassifier
from sklearn.preprocessing import PolynomialFeatures
from sklearn.ensemble import BaggingClassifier

experiment_type = "classification"

X, y = load_clf_2d("stars") 
# X, y = load_reg_2d("moons")

def make_pipeline(fold_no, X_train, X_test):
    return Pipeline([
        ("polynomial", PolynomialFeatures()),
        ("scaler", StandardScaler()),
        ("model", KNeighborsClassifier()),
        # ("model", MLPClassifier(hidden_layer_sizes=(128, 32), activation="logistic"))
    ])

experiment = CrossValidationExperiment(
    experiment_id = "Unnamed Experiment", 
    X = X, 
    y = y, 
    experiment_type=experiment_type,
    pipeline_fn = make_pipeline
)

experiment.run()