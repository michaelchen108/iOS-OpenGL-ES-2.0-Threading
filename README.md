# iOS-OpenGL-ES-2.0-Threading

This application on iOS is my implementation of how to do multithreaded rendering/drawing using OpenGL ES 2.0. I noticed that there are very few resources or completed projects on how to do a full multithreaded rendering implementation of OpenGL on mobile devices (specifically the iPhone).

The rendering process on this application was split into the "drawing" or "rendering" portion, and the "presentation" portion. All the work related to drawing to framebuffer objects and texture drawing is moved to background threads to allow the main thread to handle other more important work.
