#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window.
// Intended to be inherited from by classes that wish to specialize with custom
// rendering and input handling.
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with |title| that is positioned and sized using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, hence to ensure a
  // consistent size this function will scale the inputted width and height as
  // as appropriate for the default monitor. The window is invisible until
  // |Show| is called. Returns true if the window was created successfully.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Show the current window. Returns true if the window was successfully shown.
  bool Show();

  // Setters and getters for the window frame's position and size.
  void SetQuitOnClose(bool quit_on_close);

  // Returns the backing Scale Factor for the window.
  float GetDpiScale();

  // Returns the frame's client area rect in screen coordinates.
  RECT GetClientArea();

  // Returns the underlying Win32 HWND handle.
  HWND GetHandle();

 protected:
  // Converts a point from a DPI-aware logical coordinate to a physical
  // screen coordinate.
  Point PhysicalToLogical(HWND hwnd, const Point& point);
  Point LogicalToPhysical(HWND hwnd, const Point& point);

  // Processes and routes salient Win32 messages. Delegates handling of
  // temporary messages to the correct handler.
  virtual LRESULT
  MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                 LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclasses to perform any
  // initialization they need before the window is displayed.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically responds
  // to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) noexcept;

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  bool quit_on_close_ = false;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
