
This Dockerfile builds an image based on Ubuntu 16.04 (xenial) and Oracle JDK 
9, for the purpose of running Chrome headlessly via TestNG.

A typical development environment uses Maven2 to run TestNG and Selenium
tests, written in Java. This Dockerfile mimics that environment, adding Chrome
and Chromedriver anticipating that the test code will initialize a
Chromedriver in headless mode.

This testing approach is a little legacy-ish, but there are lots of test
libraries out there which may have the same configuration and so hopefully 
this Dockerfile may be of some use in getting headless chrome testing running
on AWS (e.g., via CodeBuild), or in a Docker farm environment.

Licensed under the MIT License.
