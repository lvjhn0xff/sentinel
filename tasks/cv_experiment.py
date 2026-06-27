from core.experiment.cv_experiment import CrossValidationExperiment 
from sklearn.preprocessing import StandardScaler

from core.datasets.clf_2d import load_clf_2d
from core.datasets.reg_2d import load_reg_2d

from imblearn.pipeline import Pipeline
from imblearn.over_sampling import SMOTE

from sklearn.neighbors import KNeighborsClassifier

experiment_type = "regression"

X, y = load_clf_2d("moons") 
# X, y = load_reg_2d("moons")

def make_pipeline(fold_no, X_train, X_test):
    return Pipeline([
        ("scaler", StandardScaler()),
        ("model", KNeighborsClassifier())
    ])

experiment = CrossValidationExperiment(
    experiment_id = "Unnamed Experiment", 
    X = X, 
    y = y, 
    experiment_type=experiment_type,
    pipeline_fn = make_pipeline
)

experiment.run()