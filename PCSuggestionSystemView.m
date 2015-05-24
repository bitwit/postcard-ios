//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCSuggestionSystemView.h"
#import "PCDataDelegate.h"
#import "Tag.h"
#import "TagSuggestionTableViewCell.h"
#import "Person.h"

@interface PCSuggestionSystemView ()

@property(nonatomic, weak) NSFetchedResultsController *tagResults;
@property(nonatomic, weak) NSFetchedResultsController *personResults;
@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic, strong) NSString *queryText;

@end

@implementation PCSuggestionSystemView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initializeView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
       // [self initializeView];
    }
    return self;
}

- (void)initializeView {
    self.dataDelegate = [PCDataDelegate sharedInstance];
    self.tagResults = [_dataDelegate fetchedTagsController];
    self.personResults = [_dataDelegate fetchedPersonsController];
    self.delegate = self;
    self.dataSource = self;
    self.filterMode = PCSuggestionSystemViewFilterModeTags;
}

- (void)setText:(NSString *)queryText withFilteringMode:(PCSuggestionSystemViewFilterMode)filterMode {
    self.queryText = queryText;
    NSArray *objectsBefore;
    NSArray *objectsAfter;

    if (filterMode == PCSuggestionSystemViewFilterModeMentions) {
        objectsBefore = self.personResults.fetchedObjects;
        [_dataDelegate filterPersonsByString:queryText];
        objectsAfter = self.personResults.fetchedObjects;
    } else {
        //tags as default
        objectsBefore = self.tagResults.fetchedObjects;
        [_dataDelegate filterTagsByString:queryText];
        objectsAfter = self.tagResults.fetchedObjects;
    }

    if (objectsBefore.count == 0 && objectsAfter.count == 0) {
        return; //no change needed
    }
    /*

    [self beginUpdates];
    if(filterMode != _filterMode){
        //we changed filterModes when we setText this time, so clear all rows, except one (representing the Empty filler row)
        [self deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    _filterMode = filterMode; //we can set this now we know what's changed filter-wise

    if (objectsBefore.count > 0) {
        for (id objectBefore in objectsBefore) {
            if ([objectsAfter indexOfObject:objectBefore] == NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[objectsBefore indexOfObject:objectBefore] inSection:0];

                [self deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
    } else {
        //WAS an empty table so we have remove the "start typing..." suggestions
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    if (objectsAfter.count > 0) {
        for (id objectAfter in objectsAfter) {
            if ([objectsBefore indexOfObject:objectAfter] == NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[objectsAfter indexOfObject:objectAfter] inSection:0];

                [self insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
    } else {
        //Empty table so we have one row to put in
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self endUpdates];
     */
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (_filterMode == PCSuggestionSystemViewFilterModeMentions) {
        if (_personResults.fetchedObjects.count == 0) {
            TagSuggestionTableViewCell *tagCell = (TagSuggestionTableViewCell *) cell;
            tagCell.valueLabel.text = (_queryText.length == 0) ? @"Start typing..." : @"No Suggestions";
            tagCell.valueLabel.textColor = [UIColor whiteColor];
            tagCell.valueLabel.font = [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:16.0f];
            [tagCell.valueLabel updateConstraints];
        } else {
            Person *person = [self.personResults.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
            TagSuggestionTableViewCell *tagCell = (TagSuggestionTableViewCell *) cell;
            tagCell.valueLabel.text = [NSString stringWithFormat:@"@%@", person.username];
            tagCell.valueLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
            tagCell.valueLabel.textColor = [UIColor whiteColor];
            [tagCell.valueLabel updateConstraints];
        }
    } else {
        //tags as default
        if (_tagResults.fetchedObjects.count == 0) {
            TagSuggestionTableViewCell *tagCell = (TagSuggestionTableViewCell *) cell;
            tagCell.valueLabel.text = (_queryText.length == 0) ? @"Start typing..." : @"No Suggestions";
            tagCell.valueLabel.textColor = [UIColor whiteColor];
            tagCell.valueLabel.font = [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:16.0f];
            [tagCell.valueLabel updateConstraints];
        } else {
            Tag *tag = [self.tagResults.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
            TagSuggestionTableViewCell *tagCell = (TagSuggestionTableViewCell *) cell;
            tagCell.valueLabel.text = [NSString stringWithFormat:@"#%@", tag.value];
            tagCell.valueLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
            tagCell.valueLabel.textColor = [UIColor whiteColor];
            [tagCell.valueLabel updateConstraints];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = 1;
    return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count;

    if (_filterMode == PCSuggestionSystemViewFilterModeMentions) {
        count = _personResults.fetchedObjects.count;
    } else {
        //tags as default
        count = _tagResults.fetchedObjects.count;
    }

    count = (count > 0) ? count : 1;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TagSuggestionCell";

    TagSuggestionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HorizontalTableViewCell" owner:nil options:nil];
        for (id object in nib) {
            if ([object isKindOfClass:[TagSuggestionTableViewCell class]]) {
                cell = (TagSuggestionTableViewCell *) object;
            }
        }
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}


#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_filterMode == PCSuggestionSystemViewFilterModeMentions && _personResults.fetchedObjects.count == 0) {
        return nil;
    } else if (_filterMode == PCSuggestionSystemViewFilterModeTags && _tagResults.fetchedObjects.count == 0) {
        return nil;
    }
    return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_filterMode == PCSuggestionSystemViewFilterModeMentions && _personResults.fetchedObjects.count > 0) {
        Person *person = [self.personResults.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
        [self.suggestionDelegate suggestionSystemView:self didSelectText:person.username];
    } else if (_filterMode == PCSuggestionSystemViewFilterModeTags && _tagResults.fetchedObjects.count > 0) {
        Tag *tag = [self.tagResults.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
        [self.suggestionDelegate suggestionSystemView:self didSelectText:tag.value];
    }
   // [self deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TagSuggestionCell";

    TagSuggestionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HorizontalTableViewCell" owner:nil options:nil];
        for (id object in nib) {
            if ([object isKindOfClass:[TagSuggestionTableViewCell class]]) {
                cell = (TagSuggestionTableViewCell *) object;
            }
        }
    }

    [self configureCell:cell atIndexPath:indexPath];

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width + 1.0f;  //use width because we are going horizontal
    return height;
}


@end