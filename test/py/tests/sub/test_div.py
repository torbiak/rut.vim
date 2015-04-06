import unittest
import sub.div as div

class TestDiv(unittest.TestCase):
    def test_div(self):
        self.assertEqual(div.div(3, 1), 3)

    def test_fail_div(self):
        self.assertTrue(False)
