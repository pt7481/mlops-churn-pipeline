"""
This file contains tests for the fetch_model function.
"""

import unittest
from unittest.mock import MagicMock
from unittest.mock import patch

from churn_prediction_pipeline import fetch_model

"""
Test class for the fetch_model function.
This class contains unit tests to ensure that the fetch_model function
correctly retrieves a model from MLflow and handles errors appropriately.
"""


class TestFetchModel(unittest.TestCase):

    def setUp(self):
        self.patcher_mlflow = patch("churn_prediction_pipeline.mlflow")
        self.patcher_logger = patch("churn_prediction_pipeline.get_run_logger")

        self.mock_mlflow = self.patcher_mlflow.start()
        self.mock_logger = self.patcher_logger.start()

    def tearDown(self):
        self.patcher_mlflow.stop()
        self.patcher_logger.stop()

    @patch("prefect.blocks.system.Secret.load")
    def test_fetch_model_success(self, mock_secret_load):
        """
        Test that fetch_model retrieves the model correctly.
        """

        mock_secret = MagicMock()
        mock_secret.get.return_value = "mock-tracking-uri"
        mock_secret_load.return_value = mock_secret

        mock_model = MagicMock()
        mock_model.input_example = {"feature1": "value1", "feature2": "value2"}
        self.mock_mlflow.pyfunc.load_model.return_value = mock_model

        model = fetch_model.fn("test_model", "latest")

        self.assertEqual(
            model.input_example, {"feature1": "value1", "feature2": "value2"}
        )
        self.mock_mlflow.pyfunc.load_model.assert_called_once_with(
            model_uri="models:/test_model@latest"
        )

    @patch("prefect.blocks.system.Secret.load")
    def test_fetch_model_invalid_model_uri(self, mock_secret_load):
        """
        Test that fetch_model raises expected error type with
        the expected error message when the model is not found.
        """

        mock_secret = MagicMock()
        mock_secret.get.return_value = "mock-tracking-uri"
        mock_secret_load.return_value = mock_secret

        expected_error = (
            "Failed to fetch model 'missing_model' with alias 'latest' - "
            "Does it exist in the MLFlow registry?'"
        )
        self.mock_mlflow.pyfunc.load_model.side_effect = RuntimeError(expected_error)

        with self.assertRaises(RuntimeError) as context:
            fetch_model.fn("missing_model", "latest")

        self.assertTrue(str(context.exception).startswith(expected_error))
