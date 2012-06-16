#ifndef _HELLO_H_
#define _HELLO_H_

#include <FApp.h>
#include <FBase.h>
#include <FSystem.h>
#include <FUi.h>

/**
 * Application must inherit from Application class
 * which provides basic features necessary to define an application.
 */
class Hello :
	public Osp::App::Application,
	public Osp::System::IScreenEventListener
{
public:
	/**
	 * Application must have a factory method that creates an instance of itself.
	 */
	static Osp::App::Application* CreateInstance(void);

	Hello();
	~Hello();

	// Called when the application is initializing.
	bool OnAppInitializing(Osp::App::AppRegistry& appRegistry);

	// Called when the application is terminating.
	bool OnAppTerminating(Osp::App::AppRegistry& appRegistry, bool forcedTermination = false);

	// Called when the application's frame moves to the top of the screen.
	void OnForeground(void);

	// Called when this application's frame is moved from top of the screen to the background.
	void OnBackground(void);

	// Called when the system memory is not sufficient to run the application any further.
	void OnLowMemory(void);

	// Called when the battery level changes.
	void OnBatteryLevelChanged(Osp::System::BatteryLevel batteryLevel);

	// Called when the screen turns on.
	void OnScreenOn (void);

	// Called when the screen turns off.
	void OnScreenOff (void);
};

#endif // _HELLO_H_
