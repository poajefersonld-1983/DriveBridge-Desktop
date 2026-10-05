import unittest
from drivebridge.core import config_dir

class DistributionTests(unittest.TestCase):
    def test_configuration_is_separate(self):
        self.assertEqual(config_dir().name, "drivebridge-desktop")
