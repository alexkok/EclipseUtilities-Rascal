package javamethods;

import io.usethesource.vallang.IBool;
import io.usethesource.vallang.IValueFactory;

import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.PlatformUI;

public class IDE {
    
    private final IValueFactory values;

    public IDE(final IValueFactory values) {
    	this.values = values;
    }
    
    public void saveAllEditors(final IBool confirm) {
        Display.getDefault().syncExec(new Runnable() { // save all editors needs to be called by the ui thread!
            @Override
            public void run() {
            	PlatformUI.getWorkbench().saveAllEditors(confirm.getValue());
            }
        });
    }
}