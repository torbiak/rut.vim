import unittest
import toplevel

class TestTopLevel(unittest.TestCase):
    def test_add(self):
        self.assertEqual(toplevel.add(1, 1), 2)

    def test_fail_toplevel(self):
        self.assertTrue(False)
