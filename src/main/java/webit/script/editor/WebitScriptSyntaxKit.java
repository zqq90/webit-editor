package webit.script.editor;

import jsyntaxpane.DefaultSyntaxKit;

/**
 *
 * @author zqq90
 */
public class WebitScriptSyntaxKit extends DefaultSyntaxKit {

    public WebitScriptSyntaxKit() {
        super(new WebitScriptLexer());
    }
}
