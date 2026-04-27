using System;
using System.Runtime;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;

public sealed class ClockWindow : Window
{
    private readonly TextBlock _time, _date, _timeShadow, _dateShadow;

    [DllImport("user32.dll")] private static extern int GetWindowLong(IntPtr h, int idx);
    [DllImport("user32.dll")] private static extern int SetWindowLong(IntPtr h, int idx, int v);
    [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] private static extern int GetSystemMetrics(int idx);
    [DllImport("kernel32.dll")] private static extern bool SetProcessWorkingSetSize(IntPtr proc, IntPtr min, IntPtr max);
    [DllImport("kernel32.dll")] private static extern IntPtr GetCurrentProcess();
    [DllImport("psapi.dll")] private static extern bool EmptyWorkingSet(IntPtr proc);

    public ClockWindow()
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        ShowInTaskbar = false;
        Topmost = false;
        ResizeMode = ResizeMode.NoResize;
        SizeToContent = SizeToContent.WidthAndHeight;
        Title = "DesktopClock";
        Focusable = false;
        IsHitTestVisible = false;
        UseLayoutRounding = true;
        SnapsToDevicePixels = true;
        TextOptions.SetTextRenderingMode(this, TextRenderingMode.ClearType);

        var fam = new FontFamily("Segoe UI");
        var timeBrush = new SolidColorBrush(Color.FromRgb(0x1A, 0x1A, 0x1A));  timeBrush.Freeze();
        var dateBrush = new SolidColorBrush(Color.FromRgb(0x44, 0x44, 0x44));  dateBrush.Freeze();
        var shadowBrush = new SolidColorBrush(Color.FromArgb(0x60, 0xFF, 0xFF, 0xFF));  shadowBrush.Freeze();

        // Manual shadow via stacked TextBlocks instead of DropShadowEffect — avoids GPU shader pipeline
        _timeShadow = MakeTimeTextBlock(fam, shadowBrush);
        _time       = MakeTimeTextBlock(fam, timeBrush);
        _dateShadow = MakeDateTextBlock(fam, shadowBrush);
        _date       = MakeDateTextBlock(fam, dateBrush);

        var timeGrid = new Grid();
        timeGrid.Children.Add(_timeShadow);
        timeGrid.Children.Add(_time);

        var dateGrid = new Grid();
        dateGrid.Children.Add(_dateShadow);
        dateGrid.Children.Add(_date);

        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(32, 12, 32, 12)
        };
        stack.Children.Add(timeGrid);
        stack.Children.Add(dateGrid);
        Content = stack;

        UpdateText();

        var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(30) };
        timer.Tick += (s, e) => UpdateText();
        timer.Start();

        Loaded += OnLoaded;
        SourceInitialized += OnSourceInit;
    }

    private static TextBlock MakeTimeTextBlock(FontFamily fam, Brush brush)
    {
        return new TextBlock
        {
            FontFamily = fam,
            FontSize = 92,
            FontWeight = FontWeights.Medium,
            Foreground = brush,
            TextAlignment = TextAlignment.Center,
            LineHeight = 92,
            Margin = new Thickness(0, 0, 0, 4)
        };
    }

    private static TextBlock MakeDateTextBlock(FontFamily fam, Brush brush)
    {
        return new TextBlock
        {
            FontFamily = fam,
            FontSize = 15,
            FontWeight = FontWeights.Normal,
            Foreground = brush,
            TextAlignment = TextAlignment.Center
        };
    }

    private void UpdateText()
    {
        var n = DateTime.Now;
        var t = n.ToString("h:mm");
        var d = n.ToString("dddd, MMMM d");
        _time.Text = t;        _timeShadow.Text = t;
        _date.Text = d;        _dateShadow.Text = d;
    }

    private void OnLoaded(object s, RoutedEventArgs e)
    {
        var src = PresentationSource.FromVisual(this);
        double dpi = src != null ? src.CompositionTarget.TransformToDevice.M11 : 1.0;
        double logicalW = GetSystemMetrics(0) / dpi;  // SM_CXSCREEN = 0
        Left = (logicalW - ActualWidth) / 2;
        Top = 24;

        // After first frame, drop heap pressure + force OS to trim working set
        Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(TrimMemory));

        // Periodic trim every 5 minutes (WPF can grow over time)
        var trimTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(5) };
        trimTimer.Tick += (a, b) => TrimMemory();
        trimTimer.Start();
    }

    private static void TrimMemory()
    {
        GCSettings.LatencyMode = GCLatencyMode.SustainedLowLatency;
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
        // Force OS to page out everything that can be paged
        EmptyWorkingSet(GetCurrentProcess());
        // Tell scheduler the desired range — -1, -1 means trim now
        SetProcessWorkingSetSize(GetCurrentProcess(), (IntPtr)(-1), (IntPtr)(-1));
    }

    private void OnSourceInit(object s, EventArgs e)
    {
        var h = new WindowInteropHelper(this).Handle;
        int ex = GetWindowLong(h, -20);
        SetWindowLong(h, -20, ex | 0x20 | 0x80000 | 0x80 | 0x08000000);
        SetWindowPos(h, (IntPtr)1, 0, 0, 0, 0, 0x13);
    }

    [STAThread]
    public static void Main()
    {
        var app = new Application { ShutdownMode = ShutdownMode.OnLastWindowClose };
        app.Run(new ClockWindow());
    }
}
