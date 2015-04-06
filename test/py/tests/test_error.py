import unittest
import error

class TestError(unittest.TestCase):
    def test_mul(self):
        self.assertEqual(toplevel.mul(1, 1), 1)

    def test_fail_error(self):
        self.assertTrue(False)
