/*
Venbrace grammar v1.1: complete verbose form
logs:
-- v1.0: complete translation from original design draft
-- v1.1: migrated and modified the TAIL grammar
-- v1.2: only supports non-ambiguous blocks
Author: Ruanqianqian Huang
Date: Jan 3, 2020
Modified: Feb 27, 2020
*/

// ==========GRAMMAR MACROS==========
grammar Venbrace;

options
{
  language = 'JavaScript';
  tokenVocab=VenbraceLexer;
}

@lexer::members{
  var idType = "label";
	var errors = [];
  // var tokens = [];

  // VenbraceLexer.prototype.nextToken = function() {
  //     var t = antlr4.Lexer.prototype.nextToken();
  //     if (t.type !== antlr4.Token.EOF)
  //       tokens.push(t);
  //     return t;
  // }

  // VenbraceLexer.prototype.getAllTokens = function() {
  //   return tokens;
  // }

  VenbraceLexer.prototype.emitErrorMessage = function(error) {
  	    //var hdr = getErrorHeader(e);
        //var msg = getErrorMessage(e, tokenNames);
        errors.push(error);
    }
  VenbraceLexer.prototype.getErrors = function() {
        return errors;
    }

  VenbraceLexer.prototype.setTokenFactory = function(newFactory) {
    factory = newFactory;
  }
}

@parser::members{

	var errors = [];
  // var tokens = [];

  // VenbraceParser.prototype.match = function(ttype) {
  //   tokens.push(antlr4.Parser.prototype.getCurrentToken());
  //   //antlr4.Parser.prototype.match(ttype);
  // }

  // VenbraceParser.prototype.getAllTokens = function() {
  //   return tokens;
  // }

  VenbraceParser.prototype.emitErrorMessage = function(error) {
        //var hdr = getErrorHeader(e);
        //var msg = getErrorMessage(e, tokenNames);
        // errors.push(error);
        console.log(error);
    };
  VenbraceParser.prototype.getErrors = function() {
        return errors;
    };
  VenbraceParser.prototype.recoverFromMismatchedToken = function(input, ttype, follow){
  	throw new antlr4.runtime.MismatchedTokenException(ttype, input);
  }

  document.createVenbraceElement = function (tagName) {
        var element = document.createElement(tagName);
        element.appendChildReal = element.appendChild; // save original appendChild method
        element.appendChild = function (child) { 
          if (child) {
            element.appendChildReal(child); // Only append child if not null
          } 
        };
        return element;
    }


  // VenbraceException = function(msg) {
  //   VenbraceException.superclass.constructor.call(this, msg);
  //   this.message = msg;
  // };
  // antlr4.error.extend(VenbraceException, Error, {
  //   name: "antlr4.runtime.VenbraceException"
  // });  

  // VenbraceParser.prototype.isValidComponentName = function(componentName){
  // 	var componentInstance = Blockly.ComponentInstances[componentName];
  // 	//from appinventor/blocklyeditor/src/component.js
  // 	return (typeof componentInstance == "object" && componentInstance.uid != null);
  // };
  // VenbraceParser.prototype.isValidComponentFieldName = function(fields, componentType, fieldName){
  // 	//I am using "field" as a general name for event, property or method
  // 	//fields should be of the form "events", "properties", or "methods"
  // 	var componentInfo = Blockly.ComponentTypes[componentType].componentInfo;
	// 	var componentFields = componentInfo[fields];
	// 	for (var i = 0; i<componentFields.length; i++){
	// 		if(componentFields[i].name === fieldName){
	// 			return true;
	// 		}
	// 	}
	// 	return false;
  // };
}

@rulecatch{
	catch (re){
		throw re;
	}
}



// ==========PARSER RULES==========

program returns [var elt]
@init{
  $elt = document.createVenbraceElement("xml");
}
: (decl_block {$elt.appendChild($decl_block.elt);})* EOF;
catch [e] {emitErrorMessage(e);}

// test rule
test_program returns [var elt]
@init {
  $elt = document.createVenbraceElement("xml");
}
: (decl_block {$elt.appendChild($decl_block.elt);})
| (stat_block {$elt.appendChild($stat_block.elt);})
| (expr_block {$elt.appendChild($expr_block.elt);})
;
catch [e] {emitErrorMessage(e);}

//program: /* lang_config */ screen* EOF;
//lang_config: '%' lang;

// SCREEN ELEMENTS
//
// ===Jan 27, 2020===
// - has to have screen dividers as for now
// 
//screen: screen_divider decl* ;
//screen_divider: DIVIDER ID DIVIDER;

// FOR TESTING
//screen: decl+;

// TOP-LEVEL DECL BLOCKS
/* Examples:
1. [to proc arg do {}]
2. [to proc arg result ()]
3. [$ id <- ()]
 */
decl_block returns [var elt]
  : LSQR decl RSQR {$elt = $decl.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

/* Feb 28 2020: procedure decls removed from user study 1 */
decl returns [var elt]
  : global_decl {$elt = $global_decl.elt;}
  | procedure_do {$elt = $procedure_do.elt;}
  | procedure_result {$elt = $procedure_result.elt;}
  | event_handler {$elt = $event_handler.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

// 04/20/20: only keep the verbose version
global_decl returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","global_declaration");
	$elt.setAttribute("inline","false");

	var field = document.createVenbraceElement("field");
	field.setAttribute("name","NAME");
	var value = document.createVenbraceElement("value");
	value.setAttribute("name","VALUE");
}
  : 
  (INITIALIZE GLOBAL ID TO expr_block
  {
		field.innerHTML = $ID.text;
		value.appendChild($expr_block.elt);
		$elt.appendChild(field);
		$elt.appendChild(value);
	}
  )
  ;
  catch [e] {emitErrorMessage(e);}


procedure_do returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","procedures_defnoreturn");

	var hasMutations = false;
	var mutation = document.createVenbraceElement("mutation");
	var argsCount = 0;

	var name = document.createVenbraceElement("field");
	name.setAttribute("name","NAME");

	var var_field_arr = [];
}
  : TO proc_name=ID {name.innerHTML = $proc_name.text;}
  (arg_name=ID {
        hasMutations = true;
        var arg = document.createVenbraceElement("arg");
        arg.setAttribute("name",$arg_name.text);
        mutation.appendChild(arg);
        var var_field = document.createVenbraceElement("field");
        var_field.setAttribute("name","VAR"+argsCount);
        var_field.innerHTML = $arg_name.text;
        var_field_arr.push(var_field);
        argsCount++;
      }
  )* 
  DO suite {
      if(hasMutations){
        $elt.appendChild(mutation);
      }
      $elt.appendChild(name);
      for(var i=0; i<var_field_arr.length; i++){
        $elt.appendChild(var_field_arr[i]);
      }
      var seq = $suite.elt;
      seq.setAttribute("name","STACK");
      $elt.appendChild(seq);
    }
  ;
  catch [e] {emitErrorMessage(e);}
  

procedure_result returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","procedures_defreturn");

	var hasMutations = false;
	var mutation = document.createVenbraceElement("mutation");
	var argsCount = 0;

	var name = document.createVenbraceElement("field");
	name.setAttribute("name","NAME");

	var var_field_arr = [];

	var value = document.createVenbraceElement("value");
	value.setAttribute("name","RETURN");
}
  : TO proc_name=ID {name.innerHTML = $proc_name.text;}
  (arg_name=ID {
	 	  hasMutations = true;
	 	  var arg = document.createVenbraceElement("arg");
	 	  arg.setAttribute("name",$arg_name.text);
	 	  mutation.appendChild(arg);
	 	  var var_field = document.createVenbraceElement("field");
	 	  var_field.setAttribute("name","VAR"+argsCount);
	 	  var_field.innerHTML = $arg_name.text;
	 	  var_field_arr.push(var_field);
	 	  argsCount++;
	 	})* 
  RESULT expr_block {
	 	if(hasMutations){
	 		$elt.appendChild(mutation);
	 	}
	 	$elt.appendChild(name);
	 	for(var i=0; i<var_field_arr.length; i++){
	 		$elt.appendChild(var_field_arr[i]);
	 	}
	 	value.appendChild($expr_block.elt);
	 	$elt.appendChild(value);
	 }
  ;
  catch [e] {emitErrorMessage(e);}


//TODO: ADD OTHER EVENT HANDLERS; HANDLE INVALID/VALID COMPONENTS
event_handler returns [var elt]
@init {
  $elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","component_event");
	var mutation = document.createVenbraceElement("mutation");
	//mutation.setAttribute("component_type",)
	//mutation attributes will be set inside the body of the rule
	//dotted names allow spaces...which we don't want allowed...
	var field = document.createVenbraceElement("field");
	field.setAttribute("name","COMPONENT_SELECTOR");
}
  : WHEN COMPONENT_PROPERTY //component=ID DOT event=ID 
  {
		var componentName = $COMPONENT_PROPERTY.text.split(".")[0];
		var eventName = $COMPONENT_PROPERTY.text.split(".")[1];
		//var componentInstance = Blockly.ComponentInstances[componentName];
		//var componentType;
		//if (this.isValidComponentName(componentName)){
			//componentType = Blockly.Component.instanceNameToTypeName(componentName);
			//mutation.setAttribute("component_type", componentType);
      mutation.setAttribute("component_type", "Button"); //hard-coded
			mutation.setAttribute("instance_name", componentName);
			field.innerHTML = componentName;
		//} else {
			//throw new TAILException("Invalid component name: " + componentName);
			//this.emitErrorMessage("Invalid component name: " + componentName);
			//the parser will continue even after this error because syntactically this is still correct...
		//}
		//if(this.isValidComponentFieldName("events", componentType, eventName)){
			mutation.setAttribute("event_name", eventName);
		//}else{
		//	throw new VenbraceException("Invalid event name: " + eventName);
			//this.emitErrorMessage("Invalid event name: " + eventName);
		//} //no need for else case, we've already added an error to the errors array above

	} (param_name=ID {
	 	  hasMutations = true;
	 	  var arg = document.createVenbraceElement("arg");
	 	  arg.setAttribute("name",$param_name.text);
	 	  mutation.appendChild(arg);
	 	  var var_field = document.createVenbraceElement("field");
	 	  var_field.setAttribute("name","VAR"+argsCount);
	 	  var_field.innerHTML = $param_name.text;
	 	  var_field_arr.push(var_field);
	 	  argsCount++;
	 	})* 
  DO suite
  {
    var statements = $suite.elt;
    statements.setAttribute("name","DO");

    $elt.appendChild(mutation);
    $elt.appendChild(field);
    $elt.appendChild(statements);
  }
  ;
  catch [e] {emitErrorMessage(e);}


// KEY ELEMENTS
expr_block returns [var elt]
  : (LPAREN RPAREN) {$elt = document.createVenbraceElement("empty_expr");} //04/20/20: fix $elt --> empty socket type
  | atom {$elt = $atom.elt;}
  | expr {$elt = $expr.elt;};
  catch[e] {emitErrorMessage(e);}

// 04/20/20: made empty statement {}
suite returns [var elt]
@init{
	$elt = document.createVenbraceElement("suite_begin");
	var count = 0;
	var prevStatementBlock;
	var currentStatementBlock;
	var stmt_arr = [];
}
  : (stat_block
    {
		  if (count === 0){ // this is the very first statement
		  	prevStatementBlock = $stat_block.elt;
		  	$elt.appendChild(prevStatementBlock);
		  }else{ //all of the rest of the statement blocks
		  	var next = document.createVenbraceElement("next");
		  	var currentStmt = $stat_block.elt;
		  	next.appendChild(currentStmt);
		  	prevStatementBlock.appendChild(next);
		  	prevStatementBlock = currentStmt;
		  }
		  count++;
		}
  )*
 | LCURLY RCURLY;
  catch [e] {emitErrorMessage(e);}

stat_block returns [var elt]
: LCURLY (stat
    {$elt = $stat.elt;}
  ) RCURLY
  ;
  catch[e] {emitErrorMessage(e);}


stat returns [var elt]
  : (control_stat {$elt = $control_stat.elt;}
  | call_procedure_stat {$elt = $call_procedure_stat.elt;}
  | var_stat {$elt = $var_stat.elt;}
  | list_stat {$elt = $list_stat.elt;}
  );
  catch [e] {emitErrorMessage(e);}


// STATEMENT BLOCKS
/* Feb 28, 2020: keep only if_stat and while_stat for study 1 */
/* May 25, 2020: add more statements for study 2 */

list_stat returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("inline","false");
	$elt.setAttribute("type","list_stat");
}
  : ADD_ITEMS_TO_LIST label? expr_block label? expr_block;

control_stat returns [var elt]
  : if_stat {$elt = $if_stat.elt;}
  | for_each_from_to {$elt = $for_each_from_to.elt;}
  | while_stat {$elt = $while_stat.elt;}
  //| evaluate_but_ignore {$elt = $evaluate_but_ignore.elt;}
 // | open_screen {$elt = $open_screen.elt;}
 // | close_screen {$elt = $close_screen.elt;}
 // | close_application {$elt = $close_application.elt;}
  // | break {$elt = $break.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

if_stat returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("inline","false");
	$elt.setAttribute("type","if_stat");

	var mutation = document.createVenbraceElement("mutation");
	var mutations = false;
	var else_if_count = 0;
	var else_count = 0;
}
  : IF e1=expr_block {
		var val = document.createVenbraceElement("value");
		val.setAttribute("name","IF0");
		val.appendChild($e1.elt);
		$elt.appendChild(val);
	} 
  THEN s1=suite {
		var then_stmts = $s1.elt;
		then_stmts.setAttribute("name", "THEN0");
		//then_stmts.appendChild($s1.elt);
		$elt.appendChild(then_stmts);
	}
  ((ELSE_IF {mutations = true; else_if_count++;} 
    e2=expr_block{
		var value = document.createVenbraceElement("value");
		value.setAttribute("name","IF"+else_if_count);
		value.appendChild($e2.elt);
		$elt.appendChild(value);
	} THEN s2=suite {
		var else_if_stmts = $s2.elt;
		else_if_stmts.setAttribute("name","THEN"+else_if_count);
		// else_if_stmts.appendChild($s2.elt);
		$elt.appendChild(else_if_stmts);
	})* (ELSE s3=suite {
		mutations = true;
		else_count++;

		var else_stmts = $s3.elt;
		else_stmts.setAttribute("name","ELSE");
		// else_stmts.appendChild($s3.elt);
		$elt.appendChild(else_stmts);
	})?)?
	{
		if(mutations){
			if (else_if_count !== 0){
				mutation.setAttribute("elseif",else_if_count);
			}
			if (else_count !== 0){
				mutation.setAttribute("else",else_count);
			}
			$elt.insertBefore(mutation, $elt.firstElementChild);
		}
	}
  ;
  catch [e] {emitErrorMessage(e);}

//for_stat: for_each_from_to | for_each_in_list;
for_each_from_to returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("inline","false");
	$elt.setAttribute("type","controls_for");
}
  : FOREACH ID FROM from=expr_block
  {
		var from_val = document.createVenbraceElement("value");
		from_val.setAttribute("name","FROM");
		from_val.appendChild($from.elt);
    $elt.appendChild(from_val);
	}  TO to=expr_block 
  {
		var to_val = document.createVenbraceElement("value");
		to_val.setAttribute("name","TO");
		to_val.appendChild($to.elt);
    $elt.appendChild(to_val);
	} BY by=expr_block 
  {
		var by_val = document.createVenbraceElement("value");
		by_val.setAttribute("name","BY");
		by_val.appendChild($by.elt);
    $elt.appendChild(by_val);
	} DO suite
  {
		var for_stats = $suite.elt;
		for_stats.setAttribute("name", "DO");
		$elt.appendChild(for_stats);
	} ;
  catch [e] {emitErrorMessage(e);}

//for_each_in_list: FOREACH ID IN LIST expr_block DO suite;
while_stat returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("inline","false");
	$elt.setAttribute("type","controls_while");
}
  : WHILE TEST expr_block 
  {
		var val = document.createVenbraceElement("value");
		val.setAttribute("name","TEST_COND");
		val.appendChild($expr_block.elt);
		$elt.appendChild(val);
	} 
  DO suite
  {
		var while_stats = $suite.elt;
		while_stats.setAttribute("name", "DO");
		$elt.appendChild(while_stats);
	} 
  ;
  catch [e] {emitErrorMessage(e);}

evaluate_but_ignore returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("inline","false");
	$elt.setAttribute("type","evaluate_but_ignore");
}
  : EVAL_BUT_IGNORE_RESULT expr_block 
    {
      var val = document.createVenbraceElement("value");
      val.appendChild($expr_block.elt);
      $elt.appendChild(val);
    } 
  ;
  catch [e] {emitErrorMessage(e);}

// TODO: xml
open_screen returns [var elt]
@init {
    $elt = document.createVenbraceElement("block");
	  $elt.setAttribute("inline","false");
	  $elt.setAttribute("type","open_screen");
    var operation = "";
    var withValue = false;
  }
  : OPEN_ANOTHER_SCREEN name=expr_block {$elt.appendChild($name.elt);}
  (val=expr_block {
    withValue = true;
    $elt.appendChild($name.elt);
  })? 
  {
    operation = withValue ? "open_screen_with_value" : "open_screen"; 
    $elt.setAttribute("type",operation);
  }
  ; //NOTE: arbitrarily abbreviated here
  catch [e] {emitErrorMessage(e);}

close_screen returns [var elt]
  : CLOSE_SCREEN {
    $elt = document.createVenbraceElement("block");
	  $elt.setAttribute("inline","false");
	  $elt.setAttribute("type","close_screen");
  }
  ;
  catch [e] {emitErrorMessage(e);}

close_application returns [var elt]
  : CLOSE_APPLICATION {
    $elt = document.createVenbraceElement("block");
	  $elt.setAttribute("inline","false");
	  $elt.setAttribute("type","close_application");
  }
  ;
  catch [e] {emitErrorMessage(e);}

// QQ 03/23/20: turning off the option of having arguments
// 04/20/20: made `call' optional
// TODO: add arguments
call_procedure_stat returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","call_procedure_stat");
  var procname = "";
    //var argLabels = [];
    //var argExps = [];
    // var pushArgLabel = function (ID) {
    //   var labelWithoutTrailingColon = ID.substring(0,ID.length - 1);
    //   argLabels.push(labelWithoutTrailingColon);
    // };
    // var pushArgExp = function (elt) {
    //   argExps.push(elt);
    // };
}
  : (CALL? ((ID {procname = $ID.text;})
    //((PROC_DECL {procname = $PROC_DECL.text;})
    | (component=ID DOT event=ID {procname = $component.text + "." + $event.text;}))
    // (arg=expr_block
    // { pushArgExp($expr_block.elt);}
    // )* 
    {
      //var mutation = document.createVenbraceElement("mutation");
      //mutation.setAttribute("name", procname);
   	  //$elt.appendChild(mutation);

      var procnameField = document.createVenbraceElement("field");
      procnameField.setAttribute("name", "PROCNAME");
      procnameField.innerHTML = procname;
   	  $elt.appendChild(procnameField);

      /*for (var i = 0; i < argExps.length; i++) {
        //var mutationArg = document.createVenbraceElement("arg");
        //mutationArg.setAttribute("name", argLabels[i]); 
        //mutation.appendChild(mutationArg);
        var valueArg = document.createVenbraceElement("value");
        valueArg.setAttribute("name", "ARG" + i); 
        valueArg.appendChild(argExps[i]);
        $elt.appendChild(valueArg);
      }*/
    }
  )
    ;
    catch [e] {emitErrorMessage(e);}

/* Feb 28 2020: remove local_init_stat from the first user study */
var_stat returns [var elt]
  : setter {$elt = $setter.elt;}
 // | local_init_stat {$elt = $local_init_stat.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

setter returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","var_stat");
	$elt.setAttribute("inline","false");

	var field = document.createVenbraceElement("field");
	field.setAttribute("name","VAR");

	var var_name = "";

	var value = document.createVenbraceElement("value");
	value.setAttribute("name","VALUE");
}
  : SET ((GLOBAL {var_name += $GLOBAL.text + " ";})? (ID {var_name += $ID.text;})
  | (COMPONENT_PROPERTY {var_name += $COMPONENT_PROPERTY.text;}) 
  ) 
  TO expr_block {
    field.innerHTML = var_name;
		$elt.appendChild(field);
		value.appendChild($expr_block.elt);
		$elt.appendChild(value);
  };
  catch [e] {emitErrorMessage(e);}

local_init_stat returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","local_init_stat");
	var mutation = document.createVenbraceElement("mutation");
	var localName;
	var fieldArr = [];
	var field;
	var count = 0;
	var valArr = [];
	var value;
}
  : INITIALIZE LOCAL (ID TO expr_block
  {
			localName = document.createVenbraceElement("localname");
			localName.setAttribute("name",$ID.text);
			mutation.appendChild(localName);

			field = document.createVenbraceElement("field");
			field.setAttribute("name","VAR" + count);
			field.innerHTML = $ID.text;
			fieldArr.push(field);

			value = document.createVenbraceElement("value");
			value.setAttribute("name", "DECL"+count);
			value.appendChild($expr_block.elt);
			valArr.push(value);
			count++;
		}
  )+
  {
    $elt.appendChild(mutation);
    fieldArr.forEach(function(field){
      $elt.appendChild(field);
    });
    valArr.forEach(function(value){
      $elt.appendChild(value);
    });
  }
  IN suite
  {
  var seq = $suite.elt;
  seq.setAttribute("name","STACK");
  $elt.appendChild(seq);
  }
  ;
  catch [e] {emitErrorMessage(e);}

// EXPR BLOCKS
/* Feb 28, 2020: remove call_procedure_expr (maybe also list_expr?) from User Study 1 */
expr returns [var elt]
  : var_expr {$elt = $var_expr.elt;}
    | (LPAREN
        (control_expr {$elt = $control_expr.elt;}
        | logic_expr {$elt = $logic_expr.elt;}
        | not_expr {$elt = $not_expr.elt;}
        | compare_eq_expr {$elt = $compare_eq_expr.elt;}
        | compare_math_expr {$elt = $compare_math_expr.elt;}
        | math_expr {$elt = $math_expr.elt;}
        | str_expr {$elt = $str_expr.elt;}
        
        /* | component_expr*/
        | color_block {$elt = $color_block.elt;}
        //  | list_expr {$elt = $list_expr.elt;}
        | call_procedure_expr {$elt = $call_procedure_expr.elt;}
        | atom {$elt = $atom.elt;}) 
      RPAREN)
    ;
    catch [e] {emitErrorMessage(e);}

control_expr returns [var elt]
  : if_expr {$elt = $if_expr.elt;}
  | do_expr {$elt = $do_expr.elt;}
  //| get_screen_val {$elt = $get_screen_val.elt;}
  //| get_screen_text {$elt = $get_screen_text.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

if_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","if_expr");
	$elt.setAttribute("inline","false");
}
  : IF c=expr_block THEN e1=expr_block ELSE e2=expr_block
  {
		var testVal = document.createVenbraceElement("value");
		testVal.setAttribute("name","TEST");
		testVal.appendChild($c.elt);

		var thenVal = document.createVenbraceElement("value");
		thenVal.setAttribute("name","THENRETURN");
		thenVal.appendChild($e1.elt);

		var elseVal = document.createVenbraceElement("value");
		elseVal.setAttribute("name","ELSERETURN");
		elseVal.appendChild($e2.elt);

		$elt.appendChild(testVal);
		$elt.appendChild(thenVal);
		$elt.appendChild(elseVal);
	}
  ;
  catch [e] {emitErrorMessage(e);}

do_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","do_expr");
	$elt.setAttribute("inline","false");
}
  : DO suite {
    var seq = $suite.elt;
    seq.setAttribute("name","STACK");
    $elt.appendChild(seq);
    }
  RESULT expr_block {
      $elt.appendChild($expr_block.elt);
    }
  ;
  catch [e] {emitErrorMessage(e);}


get_screen_val returns [var elt]
  : GET_START_VALUE 
    {
      $elt = document.createVenbraceElement("block");
      $elt.setAttribute("type","get_screen_val");
	    $elt.setAttribute("inline","false");
    }
  ;
  catch [e] {emitErrorMessage(e);}


get_screen_text returns [var elt]
  : GET_PLAIN_START_TEXT
  {
    $elt = document.createVenbraceElement("block");
    $elt.setAttribute("type","get_screen_val");
    $elt.setAttribute("inline","false");
  }
  ;
  catch [e] {emitErrorMessage(e);}

logic_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");

	$elt.setAttribute("type","logic_operation");
	$elt.setAttribute("inline","true");

	var operation = "";
}
  : a=expr_block
  (AND {operation = "AND";}| OR {operation="OR";}) 
  b=expr_block
  {
    var field = document.createVenbraceElement("field");
    field.setAttribute("name","OP");
    field.innerHTML = operation;

    var valA = document.createVenbraceElement("value");
    valA.setAttribute("name","A");
    valA.appendChild($a.elt);

    var valB = document.createVenbraceElement("value");
    valB.setAttribute("name","B");
    valB.appendChild($b.elt);

    $elt.appendChild(valA);
    $elt.appendChild(field);
    $elt.appendChild(valB);
  }
  ;

not_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");

	$elt.setAttribute("type","logic_negate");
	$elt.setAttribute("inline","false");
}
  : NOT expr_block
  {
    var field = document.createVenbraceElement("field");
    field.setAttribute("name","OP");
    field.innerHTML = "NOT";

		var value = document.createVenbraceElement("value");
		value.setAttribute("name","BOOL");
		value.appendChild($expr_block.elt);

		$elt.appendChild(field);
    $elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}


compare_eq_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");

	$elt.setAttribute("type","logic_compare");
	$elt.setAttribute("inline","true");

	var operation = "";
}
  : a=expr_block (LOGIC_EQ {operation = "EQ";}
  | LOGIC_NOT_EQ {operation = "NEQ";}) 
  b=expr_block
  {
		var field = document.createVenbraceElement("field");
	  field.setAttribute("name","OP");
	  field.innerHTML = operation;

	  var valA = document.createVenbraceElement("value");
	  valA.setAttribute("name","A");
	  valA.appendChild($a.elt);

	  var valB = document.createVenbraceElement("value");
	  valB.setAttribute("name","B");
	  valB.appendChild($b.elt);

	  $elt.appendChild(valA);
	  $elt.appendChild(field);
	  $elt.appendChild(valB);
	}
  ;

compare_math_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");

	$elt.setAttribute("type","math_compare"); 
	//this is the only difference between this rule and the rule above
	$elt.setAttribute("inline","true");

	var operation = "";
}
  : a=expr_block 
  (EQ {operation = "EQ";}
  | NEQ {operation = "NEQ";}
  | GT {operation = "GT";}
  | GE {operation = "GE";}
  | LT {operation = "LT";}
  | LE {operation = "LE";}
  ) b=expr_block
  {
		var field = document.createVenbraceElement("field");
	  field.setAttribute("name","OP");
	  field.innerHTML = operation;

	  var valA = document.createVenbraceElement("value");
	  valA.setAttribute("name","A");
	  valA.appendChild($a.elt);

	  var valB = document.createVenbraceElement("value");
	  valB.setAttribute("name","B");
	  valB.appendChild($b.elt);

	  $elt.appendChild(valA);
	  $elt.appendChild(field);
	  $elt.appendChild(valB);
	}
  ;
  catch [e] {emitErrorMessage(e);}

math_expr returns [var elt]
  : mutable_op {$elt = $mutable_op.elt;}
  | immutable_op {$elt = $immutable_op.elt;}
  | min_max {$elt = $min_max.elt;}
  | unary_op {$elt = $unary_op.elt;}
  | mod {$elt = $mod.elt;}
  | remainder {$elt = $remainder.elt;}
  | quotient {$elt = $quotient.elt;}
  | trig {$elt = $trig.elt;}
    /*| rand_int {$elt = $rand_int.elt;}
  | rand_frac {$elt = $rand_frac.elt;}*/
  //| /*rand_set_seed_to |*/ 
  /*| rad_to_deg {$elt = $rad_to_deg.elt;}
  //| deg_to_rad {$elt = $deg_to_rad.elt;}
  //| format_as_dec {$elt = $format_as_dec.elt;}*/
  //| is_num {$elt = $is_num.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

mutable_op returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	//type will get a value inside the rule
	$elt.setAttribute("inline","true");

	//initalizing these in advance to be used later
	var mutation = document.createVenbraceElement("mutation");
	var itemCount = 0;
	var valArr = [];

	var addValue = function(element){
		var value = document.createVenbraceElement("value");
		value.setAttribute("name", "NUM" + itemCount);
		value.appendChild(element);
		valArr.push(value);
		itemCount++;
	}
}
  : a=expr_block 
  {
    addValue($a.elt);
  }
  (
    (
    PLUS b=expr_block {addValue($b.elt);}
    )+ 
    {$elt.setAttribute("type", "math_add");}
  | (
    MUL c=expr_block {addValue($c.elt);}
    )+
    {$elt.setAttribute("type", "math_multiply");}
  )
  {
    mutation.setAttribute("items",itemCount);
    $elt.appendChild(mutation);

    for (var i = 0; i<valArr.length; i++){
      $elt.appendChild(valArr[i]);
    }
  }
  ;
  catch [e] {emitErrorMessage(e);}

// not allowing a + b * c + d
immutable_op returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	//type will get a value inside the rule
	$elt.setAttribute("inline","true");
}  
  :( a=expr_block
  (
    MINUS {$elt.setAttribute("type", "math_subtract");}
    | DIV {$elt.setAttribute("type", "math_division");}
    | POW {$elt.setAttribute("type", "math_power");}
  ) 
  b=expr_block
  {
		var valA = document.createVenbraceElement("value");
	  valA.setAttribute("name","A");
	  valA.appendChild($a.elt);

	  var valB = document.createVenbraceElement("value");
	  valB.setAttribute("name","B");
	  valB.appendChild($b.elt);

	  $elt.appendChild(valA);
	  $elt.appendChild(valB);
	})
  | (a=expr_block NEG_NUM
  {
    var valA = document.createVenbraceElement("value");
	  valA.setAttribute("name","A");
	  valA.appendChild($a.elt);

	  var valB = document.createVenbraceElement("value");
    var field = document.createVenbraceElement("field");
    valB.setAttribute("type","math_number");
    valB.setAttribute("name", "B");
    field.innerHTML = $NEG_NUM.text.substring(1); //excluding the neg sign
    valB.appendChild(field);

    $elt.setAttribute("type", "math_subtract");
	  $elt.appendChild(valA);
	  $elt.appendChild(valB);
  })
  ;
  catch [e] {emitErrorMessage(e);}

 // TODO: 
 //| convert_num;
//rand_int: RANDOM_INTEGER FROM expr_block TO expr_block;
//rand_frac: RANDOM_FRACTION;
//TODO: statement -- rand_set_seed_to: 

min_max returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	//$elt.setAttribute("type","math_minmax");
	$elt.setAttribute("inline","false");

  var operation = "";

  var mutation = document.createVenbraceElement("mutation");
	var itemCount = 0;
	var valArr = [];

	var addValue = function(element){
		var value = document.createVenbraceElement("value");
		value.setAttribute("name", "NUM" + itemCount);
		value.appendChild(element);
		valArr.push(value);
		itemCount++;
	}
}
  : (MIN {operation = "math_min";} | MAX {operation="math_max";}) 
  a=expr_block {addValue($a.elt);}
  (b=expr_block {addValue($b.elt);})+
  {
    $elt.setAttribute("type",operation);
    mutation.setAttribute("items",itemCount);
    $elt.appendChild(mutation);
    for (var i = 0; i<valArr.length; i++){
      $elt.appendChild(valArr[i]);
    }
  }
  ;
  catch [e] {emitErrorMessage(e);}

unary_op returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_single");
	$elt.setAttribute("inline","false");

	var operation = "";
}
  : (SQRT {operation = "ROOT";}
  | ABS {operation = "ABS";}
  | NEG {operation = "NEG";}
  | LOG {operation = "LN";}
  | EULER {operation = "EXP";}
  | ROUND {operation = "ROUND";}
  | CEILING {operation = "CEILING";}
  | FLOOR {operation = "FLOOR";}
  ) 
  expr_block
  {
		var field = document.createVenbraceElement("field");
		field.setAttribute("name","OP");
		field.innerHTML = operation;

		var value = document.createVenbraceElement("value");
		value.setAttribute("name","NUM");
		value.appendChild($expr_block.elt);

		$elt.appendChild(field);
		$elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}

mod returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_divide");
	$elt.setAttribute("inline","true");
}
  : MODULO OF a=expr_block DIV b=expr_block
  {
		var field = document.createVenbraceElement("field");
		field.setAttribute("name","OP");
		field.innerHTML = "MODULO";

		var dividend = document.createVenbraceElement("value");
		dividend.setAttribute("name","DIVIDEND");
		dividend.appendChild($a.elt);

		var divisor = document.createVenbraceElement("value");
		divisor.setAttribute("name","DIVISOR");
		divisor.appendChild($b.elt); 

		$elt.appendChild(field);
		$elt.appendChild(dividend);
		$elt.appendChild(divisor);
	}
  ;
  catch [e] {emitErrorMessage(e);}

remainder returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_divide");
	$elt.setAttribute("inline","true");
}
  : REMAINDER OF a=expr_block DIV b=expr_block
  {
		var field = document.createVenbraceElement("field");
		field.setAttribute("name","OP");
		field.innerHTML = "REMAINDER";

		var dividend = document.createVenbraceElement("value");
		dividend.setAttribute("name","DIVIDEND");
		dividend.appendChild($a.elt);

		var divisor = document.createVenbraceElement("value");
		divisor.setAttribute("name","DIVISOR");
		divisor.appendChild($b.elt); 

		$elt.appendChild(field);
		$elt.appendChild(dividend);
		$elt.appendChild(divisor);
	}  
  ;
  catch [e] {emitErrorMessage(e);}

quotient returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_divide");
	$elt.setAttribute("inline","true");
}  
  : QUOTIENT OF a=expr_block DIV b=expr_block
  {
		var field = document.createVenbraceElement("field");
		field.setAttribute("name","OP");
		field.innerHTML = "QUOTIENT";

		var dividend = document.createVenbraceElement("value");
		dividend.setAttribute("name","DIVIDEND");
		dividend.appendChild($a.elt);

		var divisor = document.createVenbraceElement("value");
		divisor.setAttribute("name","DIVISOR");
		divisor.appendChild($b.elt); 

		$elt.appendChild(field);
		$elt.appendChild(dividend);
		$elt.appendChild(divisor);
	}   
  ;
  catch [e] {emitErrorMessage(e);}

trig returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_trig");
	$elt.setAttribute("inline","false");

	var operation = "";
}
  : (SIN {operation="SIN";}
  | COS {operation="COS";}
  | TAN {operation="TAN";}
  | ASIN {operation="ASIN";}
  | ACOS {operation="ACOS";}
  | ATAN {operation="ATAN";}
  ) 
  expr_block
  {
		var field = document.createVenbraceElement("field");
		field.setAttribute("name","OP");
		field.innerHTML = operation;

		var value = document.createVenbraceElement("value");
		value.setAttribute("name","NUM");
		value.appendChild($expr_block.elt);

		$elt.appendChild(field);
		$elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}

// TODO
//rad_to_deg: RAD_TO_DEG expr_block;
//deg_to_rad: RAD_TO_DEG expr_block;
//format_as_dec: FORMAT_AS_DEC number=expr_block places=expr_block;

// TODO: is hex, base 10, ... see app inventor document
is_num returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","math_isNum");
	$elt.setAttribute("inline","false");
}
  : IS ISNUMBER expr_block {$elt.appendChild($expr_block.elt);};
  catch [e] {emitErrorMessage(e);}

str_expr returns [var elt]
  : str_join {$elt = $str_join.elt;}
  | str_length {$elt = $str_length.elt;}
  | str_reverse {$elt = $str_reverse.elt;}
  | str_split_at_spaces {$elt = $str_split_at_spaces.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

str_length returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","text_length");
	$elt.setAttribute("inline","false");
}
  : LENGTH
  expr_block
  {
    var value = document.createVenbraceElement("value");
		value.setAttribute("name","STRING");
		value.appendChild($expr_block.elt);

		$elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}

str_join returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	//type will get a value inside the rule
	$elt.setAttribute("inline","true");

	//initalizing these in advance to be used later
	var mutation = document.createVenbraceElement("mutation");
	var itemCount = 0;
	var valArr = [];

	var addValue = function(element){
		var value = document.createVenbraceElement("value");
		value.setAttribute("name", "STRING" + itemCount);
		value.appendChild(element);
		valArr.push(value);
		itemCount++;
	}
}
  : JOIN a=expr_block 
  {
    addValue($a.elt);
  }
    (
     b=expr_block {addValue($b.elt);}
    )+ 
  {
    $elt.setAttribute("type", "text_join");
    mutation.setAttribute("items",itemCount);
    $elt.appendChild(mutation);

    for (var i = 0; i<valArr.length; i++){
      $elt.appendChild(valArr[i]);
    }
  }
  ;
  catch [e] {emitErrorMessage(e);}

str_reverse returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","text_reverse");
	$elt.setAttribute("inline","false");
}
  : REVERSE
  expr_block
  {
    var value = document.createVenbraceElement("value");
		value.setAttribute("name","STRING");
		value.appendChild($expr_block.elt);

		$elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}

str_split_at_spaces returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","text_split_at_spaces");
	$elt.setAttribute("inline","false");
}
  : SPLIT_AT_SPACES
  expr_block
  {
    var value = document.createVenbraceElement("value");
		value.setAttribute("name","STRING");
		value.appendChild($expr_block.elt);

		$elt.appendChild(value);
	}
  ;
  catch [e] {emitErrorMessage(e);}

var_expr returns [var elt]
  : getter {$elt = $getter.elt;}
  //| local_init_expr {$elt = $local_init_expr.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

// 04/20/20: made GET mandatory
getter returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","lexical_variable_get");

	var variable = "";
}
  : (ID
  | (LPAREN GET (GLOBAL {variable += "global ";})? ID RPAREN)
  {
    variable += $ID.text;
    var field = document.createVenbraceElement("field");
    field.setAttribute("name","VAR");
    field.innerHTML = variable;

    $elt.appendChild(field);
  });
  // | COMPONENT_PROPERTY
  // {
  //   variable += $COMPONENT_PROPERTY.text;
  //   var field = document.createVenbraceElement("field");
  //   field.setAttribute("name","VAR");
  //   field.innerHTML = variable;

  //   $elt.appendChild(field);
  // }
  //)
  
  catch [e] {emitErrorMessage(e);}

local_init_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","local_declaration_expression");
	var mutation = document.createVenbraceElement("mutation");
	var localName;
	var fieldArr = [];
	var field;
	var count = 0;
	var valArr = [];
	var value;
}
  : INITIALIZE (LOCAL ID TO a=expr_block
  {
    localName = document.createVenbraceElement("localname");
    localName.setAttribute("name",$ID.text);
    mutation.appendChild(localName);

    field = document.createVenbraceElement("field");
    field.setAttribute("name","VAR" + count);
    field.innerHTML = $ID.text;
    fieldArr.push(field);

    value = document.createVenbraceElement("value");
    value.setAttribute("name", "DECL"+count);
    value.appendChild($a.elt);
    valArr.push(value);
    count++;
  }
  )+ 
  {
    $elt.appendChild(mutation);
    fieldArr.forEach(function(field){
      $elt.appendChild(field);
    });
    valArr.forEach(function(value){
      $elt.appendChild(value);
    });
  }
  IN b=expr_block
  {
    var returnVal = document.createVenbraceElement("value");
    returnVal.setAttribute("name","RETURN");
    returnVal.appendChild($b.elt);
    $elt.appendChild(returnVal);
  }
  ;
  catch [e] {emitErrorMessage(e);}

// TODO: custom color (hex)
color_block returns [var elt]
  : color {$elt = $color.elt;}
  //| make_color {$elt = $make_color.elt;}
  ;
  catch [e] {emitErrorMessage(e);}

color returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	var field = document.createVenbraceElement("field");
	field.setAttribute("name","COLOR");

	var type = "color_";
}
: (BLACK {field.innerHTML="#000000"; type += $BLACK.text;}
		| BLUE {field.innerHTML="#0000ff"; type += $BLUE.text;}
    | WHITE {field.innerHTML="#ffffff"; type += $WHITE.text;}
    | MAGENTA {field.innerHTML="#ff00ff"; type += $MAGENTA.text;}
    | RED {field.innerHTML="#ff0000"; type += $RED.text;}
    | LIGHT_GRAY {field.innerHTML="#cccccc"; type += $LIGHT_GRAY.text;}
    | PINK {field.innerHTML="#ffafaf"; type += $PINK.text;}
    | GRAY {field.innerHTML="#888888"; type += $GRAY.text;}
    | ORANGE {field.innerHTML="#ffc800"; type += $ORANGE.text;}
    | DARK_GRAY {field.innerHTML="#444444"; type += $DARK_GRAY.text;}
    | YELLOW {field.innerHTML="#ffff00"; type += $YELLOW.text;}
    | GREEN {field.innerHTML="#00ff00"; type += $GREEN.text;}
    | CYAN {field.innerHTML="#00ffff"; type += $CYAN.text;}
		)
  {
    $elt.setAttribute("type",type);
    $elt.appendChild(field);
  }  
  ;
  catch [e] {emitErrorMessage(e);}


make_color returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
}
  : MAKE_COLOR expr_block
  {
    $elt.setAttribute("type","color_make_color");
    $elt.setAttribute("inline","false");
    var value = document.createVenbraceElement("value");
    value.setAttribute("name","COLORLIST");
    value.appendChild($expr_block.elt);
    $elt.appendChild(value);
  }
  ;
  catch [e] {emitErrorMessage(e);}

list_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","lists_create_with");

	var mutation = document.createVenbraceElement("mutation");
	var item_count = 0;

	var val_block_arr = [];
	var val_block;
}
  : (MAKE_LIST) /*(options: {greedy=true;}*/ (expr_block
    {
	      	item_count++; 
	      	val_block = document.createVenbraceElement("value");
	      	val_block.setAttribute("name", ("ADD" + (item_count-1)));
	      	val_block.appendChild($expr_block.elt);
	      	val_block_arr.push(val_block);
	      } 
  )*
  {
		mutation.setAttribute("items",item_count);
		$elt.appendChild(mutation);
		val_block_arr.forEach(function (block) {
			$elt.appendChild(block);
		});
	}
  ;
  catch [e] {emitErrorMessage(e);}
//TODO: component_expr
//TODO: comment block

// TODO: var name

// 04/20/20: made `call' optional
call_procedure_expr returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	$elt.setAttribute("type","procedures_callreturn");
  var procname = "";
  // var argLabels = [];
  // var argExps = [];
  // var pushArgLabel = function (ID) {
  //   var labelWithoutTrailingColon = ID.substring(0,ID.length - 1);
  //   argLabels.push(labelWithoutTrailingColon);
  // };
  // var pushArgExp = function (elt) {
  //   argExps.push(elt);
  // };
}
  : CALL? ((ID {procname = $ID.text;})
  | (component=ID DOT event=ID {procname = $component.text + "." + $event.text;})
  //(expr_block {pushArgExp($expr_block.elt);})*
  {
    // TODO: add more line according to
    var mutation = document.createVenbraceElement("mutation");
    mutation.setAttribute("name", procname);
    $elt.appendChild(mutation);

    var procnameField = document.createVenbraceElement("field");
    procnameField.setAttribute("name", "PROCNAME");
    procnameField.innerHTML = procname;
    $elt.appendChild(procnameField);

    /*for (var i = 0; i < argExps.length; i++) {
        // var mutationArg = document.createVenbraceElement("arg");
        // mutationArg.setAttribute("name", argLabels[i]); 
        // mutation.appendChild(mutationArg);
        var valueArg = document.createVenbraceElement("value");
        valueArg.setAttribute("name", "ARG" + i); 
        valueArg.appendChild(argExps[i]);
        $elt.appendChild(valueArg);
    }*/
  }
  );
  catch [e] {emitErrorMessage(e);}

// 04/20/20: separate rule for variables
variable returns [var elt]
@init {
	$elt = document.createVenbraceElement("block");
	var field = document.createVenbraceElement("field");
}
  : id_var=ID {
    //$id_var.type = VAR;
    var variable = $ID.text;
		$elt.setAttribute("type","lexical_variable_get");
    var field = document.createVenbraceElement("field");
    field.setAttribute("name","VAR");
    field.innerHTML = variable;
    $elt.appendChild(field);
	  };
  catch [e] {emitErrorMessage(e);}

// OTHER ELEMENTS
atom returns [var elt]
@init{
	$elt = document.createVenbraceElement("block");
	var field = document.createVenbraceElement("field");
}
  : NUMBER//int_literal $elt = $int_literal.elt; ORIGINAL CODE FOR int_literal
  {
    $elt.setAttribute("type","math_number");
    field.setAttribute("name","NUM");
    field.innerHTML = $NUMBER.text;
    $elt.appendChild(field);
	}
  | NEG_NUM
  {
    $elt.setAttribute("type","math_number");
    field.setAttribute("name","NUM");
    field.innerHTML = $NEG_NUM.text;
    $elt.appendChild(field);
  }
  | STRING {
		$elt.setAttribute("type","text");

		field.setAttribute("name","TEXT");
		var text = $STRING.text;
		field.innerHTML = text.substring(1,text.length-1);
		$elt.appendChild(field);
	}
  | TRUE {
		$elt.setAttribute("type","logic_boolean");

		field.setAttribute("name","BOOL");
		field.innerHTML = "TRUE";
		$elt.appendChild(field);
	}
  | FALSE {
		$elt.setAttribute("type","logic_boolean");

		field.setAttribute("name","BOOL");
		field.innerHTML = "FALSE";
		$elt.appendChild(field);
	}
  | COMPONENT_PROPERTY {
    var variable = $COMPONENT_PROPERTY.text;
		$elt.setAttribute("type","component_property");
    var field = document.createVenbraceElement("field");
    field.setAttribute("name","VAR");
    field.innerHTML = variable;
    $elt.appendChild(field);
  }
  ;
  catch [e] {emitErrorMessage(e);}

label: ID | SEGMENT;




// ==========***LEXER RULES***==========


WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) -> skip;


// === TOKENS ===

// SYMBOLS
LCURLY: '{';
RCURLY: '}';
LPAREN: '(';
RPAREN: ')';
LSQR: '[';
RSQR: ']';
COMMA: ',';
DIVIDER: '===';
DOT: '.';
ASSIGN: '<-';
COLON: ':';


//KEYWORDS

TRUE: 'true';
FALSE: 'false';
WHEN: 'when';
IF: 'if';
THEN: 'then';
ELSE: 'else';
ELSE_IF: 'else if';
FOREACH: 'for each';

DO: 'do';
RESULT: 'result';
TO: 'to';
CALL: 'call';

// variables
GET: 'get';
SET: 'set';
GLOBAL: 'global';
INITIALIZE: 'initialize';
LOCAL: 'local';

// control statements
 
IN: 'in';
BY: 'by';
FROM: 'from';
WHILE: 'while';
TEST: 'test';

EVAL_BUT_IGNORE_RESULT: 'evaluate but ignore';
OPEN_ANOTHER_SCREEN: 'open another screen';
OPEN_ANOTHER_SCREEN_WITH_START_VALUE: 'open another screen with start value';
CLOSE_SCREEN: 'close screen';
CLOSE_SCREEN_WITH_VALUE: 'close screen with value';
CLOSE_SCREEN_WITH_PLAIN_TEXT: 'close screen with plain text';
CLOSE_APPLICATION: 'close application';
SCREEN_NAME: 'screenName';
START_VALUE: 'startValue';
TEXT: 'text';
BREAK: 'break';

GET_START_VALUE: 'get start value';
GET_PLAIN_START_TEXT: 'get plain start text';

//OPERATORS
NOT: 'not';
AND: 'and';
OR: 'or';
XOR: 'xor';
LT: '<';
GT: '>';
LE: '<=';
GE: '>=';
EQ: '=';
NEQ: '!=';
LOGIC_EQ: EQ;
LOGIC_NOT_EQ: NEQ;

PLUS: '+';
MINUS: '-';
MUL: '*';
DIV: '/';
POW: '^';



//Math Ops
DECIMAL: 'decimal';
BINARY: 'binary';
OCTAL: 'octal';
HEXADECIMAL: 'hexadecimal';
BITWISE: 'bitwise';
SQRT: 'square root';
ABS: 'absolute';
NEG: 'neg';
LOG: 'log';
EULER: 'e^';
ROUND: 'round';
CEILING: 'ceiling';
FLOOR: 'floor';
RANDOM_INTEGER: 'random integer';
RANDOM_FRACTION: 'random fraction';
MIN: 'min';
MAX: 'max';
MODULO: 'modulo';
REMAINDER: 'remainder';
QUOTIENT: 'quotient';
OF: 'of';
CONVERT: 'convert';
RAD_2_DEG: 'radians to degrees';
DEG_2_RAD: 'degrees to radians';
FORMAT_AS_DECIMAL: 'format as decimal';
IS: 'is';
ISNUMBER: 'number?';
BASE10: 'Base 10?';
ISHEX: 'hexadecimal?';
ISBIN: 'binary?';
CONVERT_NUM: 'convert number';
BASE_10_TO_HEX: 'base 10 to hex';
HEX_TO_BASE_10: 'hex to base 10';
BASE_10_TO_BIN: 'base 10 to binary';
BIN_TO_BASE_10: 'binary to base 10';

SIN: 'sin';
COS: 'cos';
TAN: 'tan';
ASIN: 'asin';
ACOS: 'acos';
ATAN: 'atan';
ATAN2: 'atan2';

//String Ops
JOIN: 'join';
LENGTH: 'length';
IS_EMPTY: 'is empty';
COMPARE_TEXTS: 'compare texts';
TRIM: 'trim';
UPCASE: 'upcase';
DOWNCASE: 'downcase';
STARTS_AT: 'starts at';
// PIECE: 'piece';
CONTAINS: 'contains';
SPLIT: 'split';
SPLIT_AT_FIRST: 'split at first';
SPLIT_AT_ANY: 'split at any';
SPLIT_AT_FIRST_OF_ANY: 'split at first of any';
// AT: 'at';
// AT_LIST: 'at (list)';
SPLIT_AT_SPACES: 'split at spaces';
SEGMENT: 'segment';
// START: 'start';
REPLACE_ALL: 'replace all';
REPLACEMENT: 'replacement';
OBFUSCATED_TEXT: 'Obfuscated Text';
IS_A_STR: 'is a string?';
// THING: 'thing';
REVERSE: 'reverse';
MAPPINGS: 'mappings';
IN_TEXT: 'in text';
PREFERRING: 'preferring';
LONGEST_STRING_FIRST: 'longest string first';
DICTIONARY: 'dictionary';
// ORDER: 'order';


//lists
CREATE_EMPTY_LIST: ('create empty ')? 'list';
MAKE_LIST: 'make a list';
// LIST: 'list';
ADD_ITEMS_TO_LIST: 'add items to list';
// ITEM: 'item';
IS_IN_LIST: 'is in list?';
LENGTH_OF_LIST: 'length of list';
IS_LIST_EMPTY: 'is list empty?';
PICK_A_RANDOM_ITEM: 'pick a random item';
INDEX_IN_LIST: 'index in list';
SELECT_LIST_ITEM: 'select list item';
// INDEX: 'index';
REPLACE_LIST_ITEM: 'replace list item';
REMOVE_LIST_ITEM: 'remove list item';
APPEND_TO_LIST: 'append to list';
COPY_LIST: 'copy list';
IS_A_LIST: 'is a list?';
REVERSE_LIST: 'reverse list';
LIST_TO_CSV_ROW: 'list to csv row';
LIST_TO_CSV_TABLE: 'list to csv table';
LIST_FROM_CSV_ROW: 'list from csv row';
LIST_FROMCSV_TABLE: 'list from csv table';
LOOK_UP_IN_PAIRS: 'look up in pairs';
JOIN_ITEMS_USING_SEPARATOR: 'join items using separator';

//Colors
COLOR: 'color';
MAKE_COLOR: 'make color';
SPLIT_COLOR: 'split color';
BLACK: 'black';
BLUE: 'blue';
WHITE: 'white';
MAGENTA: 'magenta';
RED: 'red';
LIGHT_GRAY: 'light_gray';
PINK: 'pink';
GRAY: 'gray';
ORANGE: 'orange';
DARK_GRAY: 'dark_gray';
YELLOW: 'yellow';
GREEN: 'green';
CYAN: 'cyan';


// //Generic Component Block Stuff
// OF_COMPONENT: 'of_component:';
// FOR_COMPONENT: 'for_component:';
// COMPONENT: 'component';




// INTEGER
fragment DIGIT : ('0'..'9');
fragment HEX_DIGIT : (DIGIT | 'a'..'f' | 'A'..'F');
// INT : ((DIGIT)+ | '0x' (HEX_DIGIT)+);
NUMBER : ((DIGIT* DOT DIGIT+) | (DIGIT+ (DOT)?) | ('0x' (HEX_DIGIT)+));
NEG_NUM : MINUS NUMBER;


fragment ALPHA : ('a' .. 'z' | 'A' .. 'Z');
fragment ALPHA_NUM: ALPHA | DIGIT;
// OTHER CHARACTERS
fragment ESC :  '\\' .;



// identifiers
COMPONENT_PROPERTY: ID DOT ID;
//PROC_DECL: CALL? ID;
//VAR: ID;
ID : (ALPHA | '_') (ALPHA | '_' | DIGIT)*;


// STRING
STRING: ('\'' (ESC | ~('\\' | '\n' | '\''))* '\'')
	| ('"' (ESC | ~('\\' | '\n' | '"'))* '"');

// HEX
// 	: '#' ALPHA_NUM ALPHA_NUM ALPHA_NUM ALPHA_NUM ALPHA_NUM ALPHA_NUM
// 	;

